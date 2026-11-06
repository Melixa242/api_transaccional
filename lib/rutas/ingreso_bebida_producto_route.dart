import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/ingreso_bebida_producto_service.dart';

Router ingresoBebidaProductoRoutes(DbPool connection){
  final router =Router();
  final service =IngresoBebidaProductoService(connection);
  // `/api/ingreso-bebida-producto` (singular) es el nombre que usa la app: se acepta como alias.
  for (final base in const ['/api/ingreso-bebida-productos', '/api/ingreso-bebida-producto']) {
    router.get(base,(Request request ) async{
      final ingresoId = int.tryParse(request.url.queryParameters['ingreso_bebida_id'] ?? '');
      final productos = await service.obtenerTodos(ingresoBebidaId: ingresoId);
      return Response.ok(jsonEncode(productos),
        headers: {
          'Content-type':'application/json',
        },
      );
    });

    router.post(base, (Request request) async {
      final input = _validateProducto(await _readJson(request));
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
      final productoId = int.tryParse(id);
      final input = _validateProducto(await _readJson(request));
      if (productoId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

      try {
        if (!await service.editar(productoId, input.toRow())) return _notFound();
      } on MySQLServerException catch (e) {
        return _dbError(e);
      }
      return Response.ok(jsonEncode({'mensaje': 'Producto del ingreso actualizado'}),
          headers: {'Content-Type': 'application/json'});
    });

    router.delete('$base/<id>', (Request request, String id) async {
      final productoId = int.tryParse(id);
      if (productoId == null) return _badRequest('id invalido');

      final result = await service.eliminar(productoId);
      if (result.affectedRows == BigInt.zero) return _notFound();
      return Response.ok(jsonEncode({'mensaje': 'Producto del ingreso eliminado'}),
          headers: {'Content-Type': 'application/json'});
    });
  }

  return router;
}

const _mensajeCamposObligatorios = 'ingreso_bebida_id, producto_id y cantidad_ingresa son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_ProductoInput? _validateProducto(Map<String, dynamic> data) {
  final ingresoId = int.tryParse(data['ingreso_bebida_id']?.toString() ?? '');
  final productoId = int.tryParse(data['producto_id']?.toString() ?? '');
  final cantidad = double.tryParse(data['cantidad_ingresa']?.toString() ?? '');
  final precio = data['precio'] == null ? 0.0 : double.tryParse(data['precio'].toString());

  if (ingresoId == null || productoId == null || cantidad == null || cantidad <= 0 || precio == null || precio < 0) {
    return null;
  }
  return _ProductoInput(ingresoId, productoId, cantidad, precio);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado.
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409, body: jsonEncode({'error': 'Registro duplicado'}), headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'El ingreso o el producto no existen' : e.message);

class _ProductoInput {
  final int ingresoBebidaId;
  final int productoId;
  final double cantidadIngresa;
  final double precio;

  _ProductoInput(this.ingresoBebidaId, this.productoId, this.cantidadIngresa, this.precio);

  Map<String, dynamic> toRow() => {
        'ingreso_bebida_id': ingresoBebidaId,
        'producto_id': productoId,
        'cantidad_ingresa': cantidadIngresa,
        'precio': precio,
      };
}
