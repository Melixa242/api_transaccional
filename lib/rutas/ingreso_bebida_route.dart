import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/ingreso_bebida_service.dart';

Router ingresoBebidaRoutes(DbPool connection){
  final router =Router();
  final service =IngresoBebidaService(connection);
  router.get('/api/ingreso-bebidas',(Request request ) async{
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

  router.get('/api/ingreso-bebidas/<id>/productos', (Request request, String id) async {
    final ingresoId = int.tryParse(id);
    if (ingresoId == null) return _badRequest('id invalido');

    return Response.ok(jsonEncode(await service.productos(ingresoId)),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/api/ingreso-bebidas', (Request request) async {
    final input = _validateIngresoBebida(await _readJson(request));
    if (input == null) return _badRequest(_mensajeCamposObligatorios);

    try {
      final id = await service.insertar(input.toRow(), input.productos);
      return Response(201,
          body: jsonEncode({'id': id.toString()}),
          headers: {'Content-Type': 'application/json'});
    } on MySQLServerException catch (e) {
      return _dbError(e);
    }
  });

  router.put('/api/ingreso-bebidas/<id>', (Request request, String id) async {
    final ingresoId = int.tryParse(id);
    final input = _validateIngresoBebida(await _readJson(request));
    if (ingresoId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

    try {
      final affected = await service.editar(ingresoId, input.toRow(), input.productos);
      if (affected == 0) return _notFound();
    } on MySQLServerException catch (e) {
      return _dbError(e);
    }
    return Response.ok(jsonEncode({'mensaje': 'Ingreso de bebidas actualizado'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/ingreso-bebidas/<id>', (Request request, String id) async {
    final ingresoId = int.tryParse(id);
    if (ingresoId == null) return _badRequest('id invalido');

    final result = await service.eliminar(ingresoId);
    if (result.affectedRows == BigInt.zero) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Ingreso de bebidas eliminado'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}

const _mensajeCamposObligatorios =
    'nombre, fecha_ingreso y productos (producto_id, cantidad_ingresa, precio) son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_IngresoBebidaInput? _validateIngresoBebida(Map<String, dynamic> data) {
  final nombre = data['nombre'];
  final fechaIngreso = data['fecha_ingreso'];
  final descripcion = data['descripcion'] is String ? (data['descripcion'] as String).trim() : null;
  final productos = data['productos'];

  if (nombre is! String || nombre.trim().isEmpty ||
      fechaIngreso is! String || DateTime.tryParse(fechaIngreso.trim()) == null ||
      productos is! List || productos.isEmpty) {
    return null;
  }

  final parsedProductos = <Map<String, dynamic>>[];
  for (final item in productos) {
    if (item is! Map) return null;
    final productoId = int.tryParse(item['producto_id']?.toString() ?? '');
    final cantidad = double.tryParse(item['cantidad_ingresa']?.toString() ?? '');
    final precio = item['precio'] == null ? 0.0 : double.tryParse(item['precio'].toString());
    if (productoId == null || cantidad == null || cantidad <= 0 || precio == null || precio < 0) return null;
    parsedProductos.add({'producto_id': productoId, 'cantidad_ingresa': cantidad, 'precio': precio});
  }

  return _IngresoBebidaInput(nombre.trim(), descripcion == null || descripcion.isEmpty ? null : descripcion,
      fechaIngreso.trim(), parsedProductos);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado.
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409, body: jsonEncode({'error': 'Registro duplicado'}), headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'Algún producto no existe' : e.message);

class _IngresoBebidaInput {
  final String nombre;
  final String? descripcion;
  final String fechaIngreso;
  final List<Map<String, dynamic>> productos;

  _IngresoBebidaInput(this.nombre, this.descripcion, this.fechaIngreso, this.productos);

  Map<String, dynamic> toRow() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'fecha_ingreso': fechaIngreso,
      };
}
