import '../database/database.dart';
import 'dart:convert';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/venta_pago_service.dart';

Router ventaPagoRoutes(DbPool connection){
  final router =Router();
  final service =VentaPagoService(connection);
  router.get('/api/venta-pagos',(Request request ) async{
    final ventaId = int.tryParse(request.url.queryParameters['venta_id'] ?? '');
    final pagos = await service.obtenerTodos(ventaId: ventaId);
    return Response.ok(jsonEncode(pagos),
      headers: {
        'Content-type':'application/json',
      },
    );
  });

  router.post('/api/venta-pagos', (Request request) async {
    final input = _validateVentaPago(await _readJson(request));
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

  router.put('/api/venta-pagos/<id>', (Request request, String id) async {
    final pagoId = int.tryParse(id);
    final input = _validateVentaPago(await _readJson(request));
    if (pagoId == null || input == null) return _badRequest(_mensajeCamposObligatorios);

    try {
      if (!await service.editar(pagoId, input.toRow())) return _notFound();
    } on MySQLServerException catch (e) {
      return _dbError(e);
    }
    return Response.ok(jsonEncode({'mensaje': 'Pago actualizado'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/venta-pagos/<id>', (Request request, String id) async {
    final pagoId = int.tryParse(id);
    if (pagoId == null) return _badRequest('id invalido');

    final result = await service.eliminar(pagoId);
    if (result.affectedRows == BigInt.zero) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Pago eliminado'}),
        headers: {'Content-Type': 'application/json'});
  });

  return router;
}

const _mensajeCamposObligatorios = 'venta_id, metodo_pago (máx. 20 caracteres) y monto son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

_VentaPagoInput? _validateVentaPago(Map<String, dynamic> data) {
  final ventaId = int.tryParse(data['venta_id']?.toString() ?? '');
  final metodoPago = data['metodo_pago']?.toString().trim() ?? '';
  final monto = double.tryParse(data['monto']?.toString() ?? '');
  final referencia = data['referencia']?.toString().trim();

  // metodo_pago es varchar(20) en MySQL.
  if (ventaId == null || metodoPago.isEmpty || metodoPago.length > 20 || monto == null || monto < 0) {
    return null;
  }
  return _VentaPagoInput(ventaId, metodoPago, monto, referencia == null || referencia.isEmpty ? null : referencia);
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

/// 1452 = FK inexistente, 1062 = duplicado.
Response _dbError(MySQLServerException e) => e.errorCode == 1062
    ? Response(409, body: jsonEncode({'error': 'Registro duplicado'}), headers: {'Content-Type': 'application/json'})
    : _badRequest(e.errorCode == 1452 ? 'La venta no existe' : e.message);

class _VentaPagoInput {
  final int ventaId;
  final String metodoPago;
  final double monto;
  final String? referencia;

  _VentaPagoInput(this.ventaId, this.metodoPago, this.monto, this.referencia);

  Map<String, dynamic> toRow() => {
        'venta_id': ventaId,
        'metodo_pago': metodoPago,
        'monto': monto,
        'referencia': referencia,
      };
}
