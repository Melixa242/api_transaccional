import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/merma_service.dart';

Router mermaRoutes(DbPool connection){
  final router =Router();
  final service =MermaService(connection);
  router.get('/api/mermas',(Request request ) async{
    final produccionId = int.tryParse(request.url.queryParameters['produccion_id'] ?? '');
    final mermas = await service.obtenerTodos(produccionId: produccionId);
    return Response.ok(jsonEncode(mermas),
      headers: {
        'Content-type':'application/json',
      },
    );
  });

  router.post('/api/mermas', (Request request) async {
    final input = _validateMerma(await _readJson(request));
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

  router.put('/api/mermas/<id>', (Request request, String id) async {
    final mermaId = int.tryParse(id);
    final input = _validateMerma(await _readJson(request));
    if (mermaId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

    try {
      if (!await service.editar(mermaId, input.toRow())) return _notFound();
    } on MySQLServerException catch (e) {
      return _dbError(e);
    }
    return Response.ok(jsonEncode({'mensaje': 'Merma actualizada'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/mermas/<id>', (Request request, String id) async {
    final mermaId = int.tryParse(id);
    if (mermaId == null) return _badRequest('id invalido');

    final result = await service.eliminar(mermaId);
    if (result.affectedRows == BigInt.zero) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Merma eliminada'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}

const _mensajeCamposObligatorios = 'produccion_id y cantidad son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_MermaInput? _validateMerma(Map<String, dynamic> data) {
  final produccionId = int.tryParse(data['produccion_id']?.toString() ?? '');
  final cantidad = double.tryParse(data['cantidad']?.toString() ?? '');

  if (produccionId == null || cantidad == null || cantidad <= 0) return null;
  return _MermaInput(produccionId, cantidad);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado.
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409, body: jsonEncode({'error': 'Registro duplicado'}), headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'La producción no existe' : e.message);

class _MermaInput {
  final int produccionId;
  final double cantidad;

  _MermaInput(this.produccionId, this.cantidad);

  Map<String, dynamic> toRow() => {
        'produccion_id': produccionId,
        'cantidad': cantidad,
      };
}
