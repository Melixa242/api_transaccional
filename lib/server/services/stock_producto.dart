import 'package:mysql_client/mysql_client.dart';

/// Rechazo de una venta por falta de stock; la ruta lo devuelve como 400.
class StockInsuficienteException implements Exception {
  final String message;
  const StockInsuficienteException(this.message);
}

/// Mueve `productos.cantidad_actual` según los detalles de una venta.
/// Debe llamarse dentro de una transacción.
class StockProducto {
  /// Descuenta lo vendido. Lanza [StockInsuficienteException] si algún producto
  /// no alcanza. Un producto inexistente se ignora: el INSERT del detalle falla por FK.
  static Future<void> descontar(MySQLConnection conn, List<Map<String, dynamic>> detalles) async {
    for (final e in _agrupar(detalles).entries) {
      final r = await conn.execute(
        'SELECT nombre, cantidad_actual FROM productos WHERE id = :id FOR UPDATE',
        {'id': e.key},
      );
      if (r.numOfRows == 0) continue;
      final fila = r.rows.first.assoc();
      final disponible = int.parse(fila['cantidad_actual']!);
      if (disponible < e.value) {
        throw StockInsuficienteException(
            'Stock insuficiente para el producto "${fila['nombre']}". Disponible: $disponible, requerido: ${e.value}.');
      }
      await conn.execute(
        'UPDATE productos SET cantidad_actual = cantidad_actual - :cantidad, updated_at = NOW() WHERE id = :id',
        {'cantidad': e.value, 'id': e.key},
      );
    }
  }

  /// Devuelve al stock lo vendido en los detalles activos de [ventaId] (o solo del detalle [detalleId]).
  static Future<void> devolver(MySQLConnection conn, {int? ventaId, int? detalleId}) async {
    final r = await conn.execute(
      'SELECT producto_id, cantidad FROM detalle_ventas WHERE estado = 1 AND '
      '${ventaId != null ? 'venta_id = :id' : 'id = :id'}',
      {'id': ventaId ?? detalleId},
    );
    final detalles = r.rows.map((row) => row.assoc()).toList();
    for (final e in _agrupar(detalles).entries) {
      await conn.execute(
        'UPDATE productos SET cantidad_actual = cantidad_actual + :cantidad, updated_at = NOW() WHERE id = :id',
        {'cantidad': e.value, 'id': e.key},
      );
    }
  }

  /// producto_id → cantidad total (cantidad_actual es entera, como en la producción se redondea).
  static Map<int, int> _agrupar(List<Map<String, dynamic>> detalles) {
    final totales = <int, double>{};
    for (final d in detalles) {
      final id = int.parse('${d['producto_id']}');
      totales[id] = (totales[id] ?? 0) + double.parse('${d['cantidad']}');
    }
    return totales.map((id, c) => MapEntry(id, c.round()));
  }
}
