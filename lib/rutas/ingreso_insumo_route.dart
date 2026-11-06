import '../database/database.dart';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/ingreso_insumo_service.dart';

Router ingresoInsumoRoutes(DbPool connection){
  final router =Router();
  final service =IngresoInsumoService(connection);
  router.get('/api/ingreso-insumos',(Request request ) async{
    final query = request.url.queryParameters['q']?.trim() ?? '';

    late List<Map<String, dynamic>> ingresos;
    if (query.isEmpty) {
      ingresos = await service.obtenerTodos();
    } else {
      ingresos = await service.buscar(query);
    }

    return Response.ok(jsonEncode(ingresos),
      headers: {
        'Content-type':'application/json',
      },
    );
  });

  router.get('/api/ingreso-insumos/<id>/detalles', (Request request, String id) async {
    final ingresoId = int.tryParse(id);
    if (ingresoId == null) return _badRequest('id invalido');

    final detalles = await service.detalles(ingresoId);
    return Response.ok(jsonEncode(detalles),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/api/ingreso-insumos', (Request request) async {
    final data = await _readJson(request);
    final input = _validateIngresoInsumo(data);
    if (input == null) return _badRequest('fecha_ingreso y detalles (insumo_id, cantidad, precio_unitario) son obligatorios');

    final id = await service.insertar(input.fechaIngreso, input.descripcion, input.detalles);
    return Response(201,
        body: jsonEncode({'id': id.toString()}),
        headers: {'Content-Type': 'application/json'});
  });

  router.put('/api/ingreso-insumos/<id>', (Request request, String id) async {
    final ingresoId = int.tryParse(id);
    final input = _validateIngresoInsumo(await _readJson(request));
    if (ingresoId == null || input == null) {
      return _badRequest('fecha_ingreso y detalles (insumo_id, cantidad, precio_unitario) son obligatorios');
    }

    final affected = await service.editar(ingresoId, input.fechaIngreso, input.descripcion, input.detalles);
    if (affected == 0) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Ingreso de insumos actualizado'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/ingreso-insumos/<id>', (Request request, String id) async {
    final ingresoId = int.tryParse(id);
    if (ingresoId == null) return _badRequest('id invalido');

    final result = await service.eliminar(ingresoId);
    if (result.affectedRows == BigInt.zero) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Ingreso de insumos eliminado'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_IngresoInsumoInput? _validateIngresoInsumo(Map<String, dynamic> data) {
  final fechaIngreso = data['fecha_ingreso'];
  final descripcion = data['descripcion'] is String ? (data['descripcion'] as String).trim() : null;
  final detalles = data['detalles'];

  if (fechaIngreso is! String || DateTime.tryParse(fechaIngreso.trim()) == null ||
      detalles is! List || detalles.isEmpty) {
    return null;
  }

  final parsedDetalles = <Map<String, dynamic>>[];
  final insumosVistos = <int>{};
  for (final item in detalles) {
    if (item is! Map) return null;
    final insumoId = int.tryParse(item['insumo_id']?.toString() ?? '');
    final cantidad = double.tryParse(item['cantidad']?.toString() ?? '');
    final precio = double.tryParse(item['precio_unitario']?.toString() ?? '');
    if (insumoId == null || cantidad == null || cantidad <= 0 || precio == null || precio < 0) return null;
    // (ingreso_insumo_id, insumo_id) es UNIQUE: no se repite un insumo.
    if (!insumosVistos.add(insumoId)) return null;
    parsedDetalles.add({'insumo_id': insumoId, 'cantidad': cantidad, 'precio_unitario': precio});
  }

  return _IngresoInsumoInput(fechaIngreso.trim(), descripcion == null || descripcion.isEmpty ? null : descripcion, parsedDetalles);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

class _IngresoInsumoInput {
  final String fechaIngreso;
  final String? descripcion;
  final List<Map<String, dynamic>> detalles;

  _IngresoInsumoInput(this.fechaIngreso, this.descripcion, this.detalles);
}
