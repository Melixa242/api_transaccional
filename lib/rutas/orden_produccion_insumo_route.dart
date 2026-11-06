import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/orden_produccion_insumo_service.dart';

Router ordenProduccionInsumoRoutes(DbPool connection){
  final router =Router();
  final service =OrdenProduccionInsumoService(connection);
  router.get('/api/orden-produccion-insumos',(Request request ) async{
    final ordenId = int.tryParse(request.url.queryParameters['orden_produccion_id'] ?? '');
    final insumos = await service.obtenerTodos(ordenProduccionId: ordenId);
    return Response.ok(jsonEncode(insumos),
      headers: {
        'Content-type':'application/json',
      },
    );
  });

  router.post('/api/orden-produccion-insumos', (Request request) async {
    final input = _validateOrdenInsumo(await _readJson(request));
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

  router.put('/api/orden-produccion-insumos/<id>', (Request request, String id) async {
    final ordenInsumoId = int.tryParse(id);
    final input = _validateOrdenInsumo(await _readJson(request));
    if (ordenInsumoId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

    try {
      if (!await service.editar(ordenInsumoId, input.toRow())) return _notFound();
    } on MySQLServerException catch (e) {
      return _dbError(e);
    }
    return Response.ok(jsonEncode({'mensaje': 'Insumo de la orden actualizado'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/orden-produccion-insumos/<id>', (Request request, String id) async {
    final ordenInsumoId = int.tryParse(id);
    if (ordenInsumoId == null) return _badRequest('id invalido');

    final result = await service.eliminar(ordenInsumoId);
    if (result.affectedRows == BigInt.zero) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Insumo de la orden eliminado'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}

const _mensajeCamposObligatorios = 'orden_produccion_id, insumo_id y cantidad son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_OrdenInsumoInput? _validateOrdenInsumo(Map<String, dynamic> data) {
  final ordenId = int.tryParse(data['orden_produccion_id']?.toString() ?? '');
  final insumoId = int.tryParse(data['insumo_id']?.toString() ?? '');
  final cantidad = double.tryParse(data['cantidad']?.toString() ?? '');

  if (ordenId == null || insumoId == null || cantidad == null || cantidad <= 0) return null;
  return _OrdenInsumoInput(ordenId, insumoId, cantidad);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado.
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409, body: jsonEncode({'error': 'Registro duplicado'}), headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'La orden de producción o el insumo no existen' : e.message);

class _OrdenInsumoInput {
  final int ordenProduccionId;
  final int insumoId;
  final double cantidad;

  _OrdenInsumoInput(this.ordenProduccionId, this.insumoId, this.cantidad);

  Map<String, dynamic> toRow() => {
        'orden_produccion_id': ordenProduccionId,
        'insumo_id': insumoId,
        'cantidad': cantidad,
      };
}
