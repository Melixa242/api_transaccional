import '../database/database.dart';
import 'dart:convert';
import 'dart:io';
import 'package:mysql_client/exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../server/services/stock_producto.dart';
import '../server/services/venta_service.dart';

Router ventaRoutes(DbPool connection){
  final router =Router();
  final service =VentaService(connection);
  router.get('/api/ventas',(Request request ) async{
    final query = request.url.queryParameters['q']?.trim() ?? '';
    final ventas = query.isEmpty
        ? await service.obtenerTodos()
        : await service.buscar(query);
    return Response.ok(jsonEncode(ventas),
      headers: {
        'Content-type':'application/json',
      },
    );
  });

  router.get('/api/ventas/<id>/detalles', (Request request, String id) async {
    final ventaId = int.tryParse(id);
    if (ventaId == null) return _badRequest('id invalido');

    return Response.ok(jsonEncode(await service.detallesYPagos(ventaId)),
        headers: {'Content-Type': 'application/json'});
  });

  router.post('/api/ventas', (Request request) async {
    final data = await _readJson(request);
    final input = _validateVenta(data);
    if (input == null) return _badRequest(_mensajeCamposObligatorios);
    final error = _validarTotales(input);
    if (error != null) return _badRequest(error);

    final int id;
    try {
      id = await service.insertar(input.toRow(), input.detalles, input.pagos);
    } on MySQLServerException catch (e) {
      return _errorMysql(e);
    } on StockInsuficienteException catch (e) {
      return _badRequest(e.message);
    }
    return Response(201,
        body: jsonEncode({'id': id.toString()}),
        headers: {'Content-Type': 'application/json'});
  });

  router.put('/api/ventas/<id>', (Request request, String id) async {
    final ventaId = int.tryParse(id);
    final input = _validateVenta(await _readJson(request));
    if (ventaId == null || input == null) return _badRequest(_mensajeCamposObligatorios);
    final error = _validarTotales(input);
    if (error != null) return _badRequest(error);

    final int affected;
    try {
      affected = await service.editar(ventaId, input.toRow(), input.detalles, input.pagos);
    } on MySQLServerException catch (e) {
      return _errorMysql(e);
    } on StockInsuficienteException catch (e) {
      return _badRequest(e.message);
    }
    if (affected == 0) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Venta actualizada'}),
        headers: {'Content-Type': 'application/json'});
  });

  router.delete('/api/ventas/<id>', (Request request, String id) async {
    final ventaId = int.tryParse(id);
    if (ventaId == null) return _badRequest('id invalido');

    final result = await service.eliminar(ventaId);
    if (result.affectedRows == BigInt.zero) return _notFound();
    return Response.ok(jsonEncode({'mensaje': 'Venta eliminada'}),   headers: {'Content-Type': 'application/json'});
  });

  return router;
}

const _mensajeCamposObligatorios =
    'cliente_id, fecha_venta, total, detalles (producto_id, precio_unitario, cantidad) '
    'y pagos (metodo_pago, monto) son obligatorios';

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

double? _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

_VentaInput? _validateVenta(Map<String, dynamic> data) {
  final clienteId = int.tryParse(data['cliente_id']?.toString() ?? '');
  final fechaVenta = data['fecha_venta'];
  final observaciones = data['observaciones'] is String ? (data['observaciones'] as String).trim() : '';
  final opcionPago = data['opcion_pago'] is String && (data['opcion_pago'] as String).trim().isNotEmpty
      ? (data['opcion_pago'] as String).trim()
      : 'Efectivo';
  final descuento = data['descuento'] == null ? 0.0 : _asDouble(data['descuento']);
  final total = _asDouble(data['total']);
  final detalles = data['detalles'];
  final pagos = data['pagos'];

  if (clienteId == null ||
      fechaVenta is! String ||
      DateTime.tryParse(fechaVenta.trim()) == null ||
      descuento == null ||
      descuento < 0 ||
      total == null ||
      total < 0 ||
      detalles is! List ||
      detalles.isEmpty ||
      pagos is! List ||
      pagos.isEmpty) {
    return null;
  }

  final parsedDetalles = <Map<String, dynamic>>[];
  for (final item in detalles) {
    if (item is! Map) return null;
    final productoId = int.tryParse(item['producto_id']?.toString() ?? '');
    final precio = _asDouble(item['precio_unitario']);
    final cantidad = _asDouble(item['cantidad']);
    if (productoId == null || precio == null || precio < 0 || cantidad == null || cantidad <= 0) return null;
    parsedDetalles.add({
      'producto_id': productoId,
      'precio_unitario': precio,
      'cantidad': cantidad,
      // El sub_total se calcula en el servidor, no se confía en el cliente.
      'sub_total': double.parse((precio * cantidad).toStringAsFixed(2)),
    });
  }

  final parsedPagos = <Map<String, dynamic>>[];
  for (final item in pagos) {
    if (item is! Map) return null;
    final metodoPago = item['metodo_pago']?.toString().trim() ?? '';
    final monto = _asDouble(item['monto']);
    if (metodoPago.isEmpty || monto == null || monto < 0) return null;
    parsedPagos.add({'metodo_pago': metodoPago, 'monto': monto, 'referencia': item['referencia']?.toString()});
  }

  return _VentaInput(clienteId, fechaVenta.trim(), observaciones, opcionPago, descuento, total,
      parsedDetalles, parsedPagos);
}

const _epsilon = 0.01;

/// total = Σ sub_total − descuento, y Σ pagos = total.
String? _validarTotales(_VentaInput input) {
  final bruto = input.detalles.fold<double>(0, (s, d) => s + (d['sub_total'] as double));
  final esperado = bruto - input.descuento;
  if ((esperado - input.total).abs() > _epsilon) {
    return 'El total (${input.total.toStringAsFixed(2)}) debe ser la suma de los detalles '
        '(${bruto.toStringAsFixed(2)}) menos el descuento (${input.descuento.toStringAsFixed(2)}) '
        '= ${esperado.toStringAsFixed(2)}';
  }
  final pagado = input.pagos.fold<double>(0, (s, p) => s + (p['monto'] as double));
  if ((pagado - input.total).abs() > _epsilon) {
    return 'La suma de los pagos (${pagado.toStringAsFixed(2)}) debe ser igual al total (${input.total.toStringAsFixed(2)})';
  }
  return null;
}

Response _badRequest(String message) => Response(400,
    body: jsonEncode({'error': message}),
    headers: {'Content-Type': 'application/json'});

/// Traduce los rechazos de MySQL a un 400 con un mensaje que la app pueda mostrar.
Response _errorMysql(MySQLServerException e) {
  switch (e.errorCode) {
    case 1452: // FK inexistente
      if (e.message.contains('cliente_id')) return _badRequest('El cliente indicado no existe');
      if (e.message.contains('producto_id')) return _badRequest('Alguno de los productos indicados no existe');
      return _badRequest('Referencia inexistente: ${e.message}');
    case 1406: // dato demasiado largo
      if (e.message.contains('metodo_pago')) {
        return _badRequest('El metodo_pago no puede superar los 20 caracteres');
      }
      return _badRequest('Dato demasiado largo: ${e.message}');
    default:
      stderr.writeln('MySQL ${e.errorCode}: ${e.message}');
      return Response.internalServerError(
          body: jsonEncode({'error': 'Error de base de datos'}),
          headers: {'Content-Type': 'application/json'});
  }
}

Response _notFound() => Response.notFound(jsonEncode({'error': 'Registro no encontrado'}),
    headers: {'Content-Type': 'application/json'});

class _VentaInput {
  final int clienteId;
  final String fechaVenta;
  final String observaciones;
  final String opcionPago;
  final double descuento;
  final double total;
  final List<Map<String, dynamic>> detalles;
  final List<Map<String, dynamic>> pagos;
  _VentaInput(this.clienteId, this.fechaVenta, this.observaciones, this.opcionPago, this.descuento,
      this.total, this.detalles, this.pagos);

  Map<String, dynamic> toRow() => {
        'cliente_id': clienteId,
        'fecha_venta': fechaVenta,
        'observaciones': observaciones.isEmpty ? null : observaciones,
        'opcion_pago': opcionPago,
        'descuento': descuento,
        'total': total,
      };
}
