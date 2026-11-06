import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/detalle_venta_service.dart';
import '../server/services/stock_producto.dart';

Router detalleVentaRoutes(DbPool connection){
  final router =Router();
  final service =DetalleVentaService(connection);
  router.get('/api/detalle-ventas',(Request request ) async{
    final ventaId = int.tryParse(request.url.queryParameters['venta_id'] ?? '');
    final detalles = await service.obtenerTodos(ventaId: ventaId);
    return Response.ok(jsonEncode(detalles),
      headers: {
        'Content-type':'application/json',
      },
    );
  });

  router.post('/api/detalle-ventas', (Request request) async {
    final input = _validateDetalleVenta(await _readJson(request));
    if (input == null) return _badRequest(_mensajeCamposObligatorios);

    try {
      final result = await service.insertar(input.toRow());
      return Response(201,
          body: jsonEncode({'id': result.lastInsertID.toString()}),
          headers: {'Content-Type': 'application/json'});
    } on MySQLServerException catch (e) {
      return _dbError(e);
    } on StockInsuficienteException catch (e) {
      return _badRequest(e.message);
    }
  });

  router.put('/api/detalle-ventas/<id>', (Request request, String id) async {
    final detalleId = int.tryParse(id);
    final input = _validateDetalleVenta(await _readJson(request));
    if (detalleId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

    try {
      if (!await service.editar(detalleId, input.toRow())) return _notFound();
    } on MySQLServerException catch (e) {
      return _dbError(e);
    } on StockInsuficienteException catch (e) {
      return _badRequest(e.message);
    }
    return Response.ok(jsonEncode({'mensaje': 'Detalle de venta actualizado'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/detalle-ventas/<id>', (Request request, String id) async {
    final detalleId = int.tryParse(id);
    if (detalleId == null) return _badRequest('id invalido');

    final result = await service.eliminar(detalleId);
    if (result.affectedRows == BigInt.zero) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Detalle de venta eliminado'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}

const _mensajeCamposObligatorios = 'venta_id, producto_id, precio_unitario y cantidad son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_DetalleVentaInput? _validateDetalleVenta(Map<String, dynamic> data) {
  final ventaId = int.tryParse(data['venta_id']?.toString() ?? '');
  final productoId = int.tryParse(data['producto_id']?.toString() ?? '');
  final precio = double.tryParse(data['precio_unitario']?.toString() ?? '');
  final cantidad = double.tryParse(data['cantidad']?.toString() ?? '');

  if (ventaId == null || productoId == null || precio == null || precio < 0 || cantidad == null || cantidad <= 0) {
    return null;
  }
  return _DetalleVentaInput(ventaId, productoId, precio, cantidad);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado.
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409, body: jsonEncode({'error': 'Registro duplicado'}), headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'La venta o el producto no existen' : e.message);

class _DetalleVentaInput {
  final int ventaId;
  final int productoId;
  final double precioUnitario;
  final double cantidad;

  _DetalleVentaInput(this.ventaId, this.productoId, this.precioUnitario, this.cantidad);

  Map<String, dynamic> toRow() => {
        'venta_id': ventaId,
        'producto_id': productoId,
        'precio_unitario': precioUnitario,
        'cantidad': cantidad,
        // El sub_total se calcula en el servidor, no se confía en el cliente.
        'sub_total': double.parse((precioUnitario * cantidad).toStringAsFixed(2)),
      };
}
