import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';
import 'stock_producto.dart';

/// Acceso MySQL a `ventas`, `detalle_ventas` y `venta_pagos` (lado servidor / shelf).
class VentaService {
  final DbPool connection;

  VentaService(this.connection);

  static const _columnas =
      'id, cliente_id, fecha_venta, observaciones, opcion_pago, descuento, total, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos() async {
    final result = await connection.execute(
      'SELECT $_columnas FROM ventas WHERE estado = 1 ORDER BY fecha_venta DESC, id DESC',
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> buscar(String query) async {
    final result = await connection.execute(
      'SELECT $_columnas FROM ventas '
      'WHERE estado = 1 AND (observaciones LIKE :q OR fecha_venta LIKE :q OR cliente_id = :id) '
      'ORDER BY fecha_venta DESC, id DESC',
      {'q': '%$query%', 'id': int.tryParse(query) ?? -1},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<Map<String, dynamic>> detallesYPagos(int ventaId) async {
    final detalles = await connection.execute(
      'SELECT id, producto_id, precio_unitario, cantidad, sub_total FROM detalle_ventas '
      'WHERE venta_id = :id AND estado = 1',
      {'id': ventaId},
    );
    final pagos = await connection.execute(
      'SELECT id, metodo_pago, monto, referencia FROM venta_pagos WHERE venta_id = :id AND estado = 1',
      {'id': ventaId},
    );
    return {
      'detalles': detalles.rows.map((row) => row.assoc()).toList(),
      'pagos': pagos.rows.map((row) => row.assoc()).toList(),
    };
  }

  /// Inserta venta + detalles + pagos en una transacción y descuenta el stock
  /// de los productos. Devuelve el id creado.
  Future<int> insertar(Map<String, dynamic> venta, List<Map<String, dynamic>> detalles,
      List<Map<String, dynamic>> pagos) {
    return connection.transactional((conn) async {
      final result = await conn.execute(
        'INSERT INTO ventas (cliente_id, fecha_venta, observaciones, opcion_pago, descuento, total, estado, created_at, updated_at) '
        'VALUES (:cliente_id, :fecha_venta, :observaciones, :opcion_pago, :descuento, :total, 1, NOW(), NOW())',
        venta,
      );
      final id = result.lastInsertID.toInt();
      await StockProducto.descontar(conn, detalles);
      await _insertarHijos(conn, id, detalles, pagos);
      return id;
    });
  }

  /// Actualiza la venta y reemplaza detalles y pagos: devuelve al stock lo de
  /// los detalles anteriores y descuenta lo de los nuevos. Devuelve 0 si no existe.
  Future<int> editar(int id, Map<String, dynamic> venta, List<Map<String, dynamic>> detalles,
      List<Map<String, dynamic>> pagos) {
    return connection.transactional((conn) async {
      final existe = await conn.execute('SELECT 1 FROM ventas WHERE id = :id', {'id': id});
      if (existe.numOfRows == 0) return 0;

      await conn.execute(
        'UPDATE ventas SET cliente_id = :cliente_id, fecha_venta = :fecha_venta, '
        'observaciones = :observaciones, opcion_pago = :opcion_pago, descuento = :descuento, '
        'total = :total, updated_at = NOW() WHERE id = :id',
        {...venta, 'id': id},
      );
      await StockProducto.devolver(conn, ventaId: id);
      await conn.execute('DELETE FROM detalle_ventas WHERE venta_id = :id', {'id': id});
      await conn.execute('DELETE FROM venta_pagos WHERE venta_id = :id', {'id': id});
      await StockProducto.descontar(conn, detalles);
      await _insertarHijos(conn, id, detalles, pagos);
      return 1;
    });
  }

  /// Borra la venta y devuelve al stock lo vendido.
  Future<IResultSet> eliminar(int id) => connection.transactional((conn) async {
        await StockProducto.devolver(conn, ventaId: id);
        return conn.execute('DELETE FROM ventas WHERE id = :id', {'id': id});
      });

  Future<void> _insertarHijos(MySQLConnection conn, int ventaId, List<Map<String, dynamic>> detalles,
      List<Map<String, dynamic>> pagos) async {
    for (final d in detalles) {
      await conn.execute(
        'INSERT INTO detalle_ventas (venta_id, producto_id, precio_unitario, cantidad, sub_total, estado, created_at, updated_at) '
        'VALUES (:venta_id, :producto_id, :precio_unitario, :cantidad, :sub_total, 1, NOW(), NOW())',
        {...d, 'venta_id': ventaId},
      );
    }
    for (final p in pagos) {
      await conn.execute(
        'INSERT INTO venta_pagos (venta_id, metodo_pago, monto, referencia, estado, created_at, updated_at) '
        'VALUES (:venta_id, :metodo_pago, :monto, :referencia, 1, NOW(), NOW())',
        {...p, 'venta_id': ventaId},
      );
    }
  }
}
