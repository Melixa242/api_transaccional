import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/ingreso_insumo_detalle_service.dart';

Router ingresoInsumoDetalleRoutes(DbPool connection){
  final router =Router();
  final service =IngresoInsumoDetalleService(connection);
  // `/api/ingreso-insumo-detalle` (singular) es el nombre que usa la app: se acepta como alias.
  for (final base in const ['/api/ingreso-insumo-detalles', '/api/ingreso-insumo-detalle']) {
    router.get(base,(Request request ) async{
      final ingresoId = int.tryParse(request.url.queryParameters['ingreso_insumo_id'] ?? '');
      final detalles = await service.obtenerTodos(ingresoInsumoId: ingresoId);
      return Response.ok(jsonEncode(detalles),
        headers: {
          'Content-type':'application/json',
        },
      );
    });

    router.post(base, (Request request) async {
      final input = _validateDetalle(await _readJson(request));
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
      final detalleId = int.tryParse(id);
      final input = _validateDetalle(await _readJson(request));
      if (detalleId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

      try {
        if (!await service.editar(detalleId, input.toRow())) return _notFound();
      } on MySQLServerException catch (e) {
        return _dbError(e);
      }
      return Response.ok(jsonEncode({'mensaje': 'Detalle de ingreso actualizado'}),
          headers: {'Content-Type': 'application/json'});
    });

    router.delete('$base/<id>', (Request request, String id) async {
      final detalleId = int.tryParse(id);
      if (detalleId == null) return _badRequest('id invalido');

      final result = await service.eliminar(detalleId);
      if (result.affectedRows == BigInt.zero) return _notFound();
      return Response.ok(jsonEncode({'mensaje': 'Detalle de ingreso eliminado'}),
          headers: {'Content-Type': 'application/json'});
    });
  }

  return router;
}

const _mensajeCamposObligatorios = 'ingreso_insumo_id, insumo_id, cantidad y precio_unitario son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_DetalleInput? _validateDetalle(Map<String, dynamic> data) {
  final ingresoId = int.tryParse(data['ingreso_insumo_id']?.toString() ?? '');
  final insumoId = int.tryParse(data['insumo_id']?.toString() ?? '');
  final cantidad = double.tryParse(data['cantidad']?.toString() ?? '');
  final precio = double.tryParse(data['precio_unitario']?.toString() ?? '');

  if (ingresoId == null || insumoId == null || cantidad == null || cantidad <= 0 || precio == null || precio < 0) {
    return null;
  }
  return _DetalleInput(ingresoId, insumoId, cantidad, precio);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado.
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409, body: jsonEncode({'error': 'Ese insumo ya está en el ingreso'}), headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'El ingreso o el insumo no existen' : e.message);

class _DetalleInput {
  final int ingresoInsumoId;
  final int insumoId;
  final double cantidad;
  final double precioUnitario;

  _DetalleInput(this.ingresoInsumoId, this.insumoId, this.cantidad, this.precioUnitario);

  Map<String, dynamic> toRow() => {
        'ingreso_insumo_id': ingresoInsumoId,
        'insumo_id': insumoId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      };
}
