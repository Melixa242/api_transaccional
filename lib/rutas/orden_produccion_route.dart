import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/orden_produccion_service.dart';

Router ordenProduccionRoutes(DbPool connection){
  final router =Router();
  final service =OrdenProduccionService(connection);
  // `/api/ordenes` es el nombre anterior (lo usaba la app vieja y la
  // documentación): se mantiene como alias para no romper esos clientes.
  for (final base in const ['/api/orden-producciones', '/api/ordenes']) {
    router.get(base,(Request request ) async{
      final query = request.url.queryParameters['q']?.trim() ?? '';

      late List<Map<String, dynamic>> ordenes;
      if (query.isEmpty) {
        ordenes = await service.obtenerTodos();
      } else {
        ordenes = await service.buscar(query);
      }

      return Response.ok(jsonEncode(ordenes),
        headers: {
          'Content-type':'application/json',
        },
      );
    });

    router.get('$base/<id>/insumos', (Request request, String id) async {
      final ordenId = int.tryParse(id);
      if (ordenId == null) return _badRequest('id invalido');

      return Response.ok(jsonEncode(await service.insumos(ordenId)),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('$base/<id>/ejecucion', (Request request, String id) async {
      final ordenId = int.tryParse(id);
      if (ordenId == null) return _badRequest('id invalido');
      final datos = await service.datosEjecucion(ordenId);
      if (datos == null) return _notFound();
      return Response.ok(jsonEncode(datos), headers: {'Content-Type': 'application/json'});
    });

    // Ejecuta el lote pendiente: crea las producciones, descuenta el stock de los
    // insumos y suma la cantidad obtenida al producto resultante.
    router.post('$base/<id>/ejecutar', (Request request, String id) async {
      final ordenId = int.tryParse(id);
      final data = await _readJson(request);
      final cantidad = double.tryParse(data['cantidad_obtenida']?.toString() ?? '');
      if (ordenId == null) return _badRequest('id invalido');
      if (cantidad == null || cantidad < 0.01) return _badRequest('cantidad_obtenida es obligatoria (>= 0.01)');

      try {
        final result = await service.ejecutar(ordenId, cantidad);
        return Response(201, body: jsonEncode(result), headers: {'Content-Type': 'application/json'});
      } on EjecucionException catch (e) {
        return Response(e.status,
            body: jsonEncode({'error': e.message}), headers: {'Content-Type': 'application/json'});
      } on MySQLServerException catch (e) {
        return _dbError(e);
      }
    });

    router.post(base, (Request request) async {
      final input = _validateOrdenProduccion(await _readJson(request));
      if (input == null) return _badRequest(_mensajeCamposObligatorios);

      try {
        final id = await service.insertar(input.toRow(), input.insumos);
        return Response(201,
            body: jsonEncode({'id': id.toString()}),
            headers: {'Content-Type': 'application/json'});
      } on MySQLServerException catch (e) {
        return _dbError(e);
      }
    });

    router.put('$base/<id>', (Request request, String id) async {
      final ordenId = int.tryParse(id);
      final input = _validateOrdenProduccion(await _readJson(request));
      if (ordenId == null || input == null) return _badRequest(_mensajeCamposObligatorios);
      if (await service.tieneProducciones(ordenId)) {
        return _conflict('La orden ya tiene producciones registradas; sus insumos no se pueden reemplazar');
      }

      try {
        final affected = await service.editar(ordenId, input.toRow(), input.insumos);
        if (affected == 0) return _notFound();
      } on MySQLServerException catch (e) {
        return _dbError(e);
      }
      return Response.ok(jsonEncode({'mensaje': 'Orden de producción actualizada'}),
          headers: {'Content-Type': 'application/json'});
    });

    router.delete('$base/<id>', (Request request, String id) async {
      final ordenId = int.tryParse(id);
      if (ordenId == null) return _badRequest('id invalido');
      if (await service.tieneProducciones(ordenId)) {
        return _conflict('La orden ya tiene producciones registradas; no se puede eliminar');
      }

      final result = await service.eliminar(ordenId);
      if (result.affectedRows == BigInt.zero) return _notFound();
      return Response.ok(jsonEncode({'mensaje': 'Orden de producción eliminada'}),
          headers: {'Content-Type': 'application/json'});
    });
  }

  return router;
}

const _mensajeCamposObligatorios =
    'fecha_programada e insumos (insumo_id, cantidad) son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_OrdenProduccionInput? _validateOrdenProduccion(Map<String, dynamic> data) {
  final numeroOrden = data['numero_orden'];
  final fechaProgramada = data['fecha_programada'];
  final reglaRaw = data['regla_conversion_id'];
  final reglaId = reglaRaw == null || '$reglaRaw'.isEmpty ? null : int.tryParse('$reglaRaw');
  final observaciones = data['observaciones'] is String ? (data['observaciones'] as String).trim() : null;
  final insumos = data['insumos'];

  // numero_orden vacío: el servicio lo genera al insertar (OR-PRO-YYYY-MM-NNNN).
  if ((numeroOrden != null && numeroOrden is! String) ||
      fechaProgramada is! String || DateTime.tryParse(fechaProgramada.trim()) == null ||
      (reglaRaw != null && '$reglaRaw'.isNotEmpty && reglaId == null) ||
      insumos is! List || insumos.isEmpty) {
    return null;
  }

  final parsedInsumos = <Map<String, dynamic>>[];
  for (final item in insumos) {
    if (item is! Map) return null;
    final insumoId = int.tryParse(item['insumo_id']?.toString() ?? '');
    final cantidad = double.tryParse(item['cantidad']?.toString() ?? '');
    if (insumoId == null || cantidad == null || cantidad <= 0) return null;
    parsedInsumos.add({'insumo_id': insumoId, 'cantidad': cantidad});
  }

  final numero = (numeroOrden as String?)?.trim() ?? '';
  return _OrdenProduccionInput(numero.isEmpty ? null : numero, fechaProgramada.trim(), reglaId,
      observaciones == null || observaciones.isEmpty ? null : observaciones, parsedInsumos);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

Response _conflict(String message) => Response(409,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado (numero_orden es UNIQUE).
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? _conflict('Ya existe una orden con ese numero_orden')
    : _badRequest(e.errorCode == 1452 ? 'La regla de conversión o algún insumo no existen' : e.message);

class _OrdenProduccionInput {
  final String? numeroOrden;
  final String fechaProgramada;
  final int? reglaConversionId;
  final String? observaciones;
  final List<Map<String, dynamic>> insumos;

  _OrdenProduccionInput(this.numeroOrden, this.fechaProgramada, this.reglaConversionId, this.observaciones,
      this.insumos);

  Map<String, dynamic> toRow() => {
        'numero_orden': numeroOrden,
        'fecha_programada': fechaProgramada,
        'regla_conversion_id': reglaConversionId,
        'observaciones': observaciones,
      };
}
