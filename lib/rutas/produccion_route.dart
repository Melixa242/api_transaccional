import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/produccion_service.dart';

Router produccionRoutes(DbPool connection){
  final router =Router();
  final service =ProduccionService(connection);
  // `/api/produccion` (singular) es el nombre que usa la app: se acepta como alias.
  for (final base in const ['/api/producciones', '/api/produccion']) {
    router.get(base,(Request request ) async{
      final ordenInsumoId = int.tryParse(request.url.queryParameters['orden_produccion_insumo_id'] ?? '');
      final producciones = await service.obtenerTodos(ordenProduccionInsumoId: ordenInsumoId);
      return Response.ok(jsonEncode(producciones),
        headers: {
          'Content-type':'application/json',
        },
      );
    });

    router.post(base, (Request request) async {
      final input = _validateProduccion(await _readJson(request));
      if (input == null) return _badRequest(_mensajeCamposObligatorios);

      try {
        final result = await service.insertar(input.toRow());
        return Response(201,
            body: jsonEncode({'id': result.lastInsertID.toString()}),
            headers: {'Content-Type': 'application/json'});
      } on MySQLServerException catch (e) {
        return _dbError(e);
      }
    });

    router.put('$base/<id>', (Request request, String id) async {
      final produccionId = int.tryParse(id);
      final input = _validateProduccion(await _readJson(request));
      if (produccionId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

      try {
        if (!await service.editar(produccionId, input.toRow())) return _notFound();
      } on MySQLServerException catch (e) {
        return _dbError(e);
      }
      return Response.ok(jsonEncode({'mensaje': 'Producción actualizada'}),
          headers: {'Content-Type': 'application/json'});
    });

    router.delete('$base/<id>', (Request request, String id) async {
      final produccionId = int.tryParse(id);
      if (produccionId == null) return _badRequest('id invalido');

      final result = await service.eliminar(produccionId);
      if (result.affectedRows == BigInt.zero) return _notFound();
      return Response.ok(jsonEncode({'mensaje': 'Producción eliminada'}),
          headers: {'Content-Type': 'application/json'});
    });
  }

  return router;
}

const _mensajeCamposObligatorios =
    'cantidad_insumo y cantidad_obtenida son obligatorios (>= 0)';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

/// `null` si viene vacío; `-1` si viene pero no es un entero válido.
int? _optionalInt(dynamic v) => v == null || '$v'.isEmpty ? null : (int.tryParse('$v') ?? -1);

_ProduccionInput? _validateProduccion(Map<String, dynamic> data) {
  final ordenInsumoId = _optionalInt(data['orden_produccion_insumo_id']);
  final reglaId = _optionalInt(data['regla_conversion_id']);
  final productoId = _optionalInt(data['producto_id']);
  final cantidadInsumo = double.tryParse(data['cantidad_insumo']?.toString() ?? '');
  final cantidadObtenida = double.tryParse(data['cantidad_obtenida']?.toString() ?? '');
  final nivel = data['nivel'] == null ? 0 : int.tryParse(data['nivel'].toString());

  if (ordenInsumoId == -1 || reglaId == -1 || productoId == -1 ||
      cantidadInsumo == null || cantidadInsumo < 0 ||
      // Sin tope respecto al insumo: la regla convierte unidades (1 pollo → 8 piezas).
      cantidadObtenida == null || cantidadObtenida < 0 ||
      nivel == null || nivel < 0) {
    return null;
  }
  return _ProduccionInput(ordenInsumoId, reglaId, productoId, cantidadInsumo, cantidadObtenida, nivel);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado (orden_produccion_insumo_id es UNIQUE).
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409,
        body: jsonEncode({'error': 'Ese insumo de la orden ya tiene una producción registrada'}),
        headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'El insumo de la orden, la regla o el producto no existen' : e.message);

class _ProduccionInput {
  final int? ordenProduccionInsumoId;
  final int? reglaConversionId;
  final int? productoId;
  final double cantidadInsumo;
  final double cantidadObtenida;
  final int nivel;

  _ProduccionInput(this.ordenProduccionInsumoId, this.reglaConversionId, this.productoId, this.cantidadInsumo,
      this.cantidadObtenida, this.nivel);

  Map<String, dynamic> toRow() => {
        'orden_produccion_insumo_id': ordenProduccionInsumoId,
        'regla_conversion_id': reglaConversionId,
        'producto_id': productoId,
        'cantidad_insumo': cantidadInsumo,
        'cantidad_obtenida': cantidadObtenida,
        'nivel': nivel,
      };
}
