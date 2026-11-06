import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';
import 'stock_producto.dart';

/// Acceso MySQL a `detalle_ventas` (lado servidor / shelf).
class DetalleVentaService {
  final DbPool connection;

  DetalleVentaService(this.connection);

  static const _columnas = 'id, venta_id, producto_id, precio_unitario, cantidad, sub_total, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos({int? ventaId}) async {
    final result = ventaId == null
        ? await connection.execute('SELECT $_columnas FROM detalle_ventas WHERE estado = 1 ORDER BY id DESC')
        : await connection.execute(
            'SELECT $_columnas FROM detalle_ventas WHERE estado = 1 AND venta_id = :venta_id ORDER BY id',
            {'venta_id': ventaId},
          );
    return result.rows.map((row) => row.assoc()).toList();
  }

  /// Inserta el detalle y descuenta el stock del producto.
  Future<IResultSet> insertar(Map<String, dynamic> data) => connection.transactional((conn) async {
        await StockProducto.descontar(conn, [data]);
        return conn.execute(
          'INSERT INTO detalle_ventas (venta_id, producto_id, precio_unitario, cantidad, sub_total, estado, created_at, updated_at) '
          'VALUES (:venta_id, :producto_id, :precio_unitario, :cantidad, :sub_total, 1, NOW(), NOW())',
          data,
        );
      });

  /// Devuelve al stock la cantidad anterior y descuenta la nueva.
  /// Devuelve false si el registro no existe.
  Future<bool> editar(int id, Map<String, dynamic> data) => connection.transactional((conn) async {
        final existe = await conn.execute('SELECT 1 FROM detalle_ventas WHERE id = :id', {'id': id});
        if (existe.numOfRows == 0) return false;
        await StockProducto.devolver(conn, detalleId: id);
        await StockProducto.descontar(conn, [data]);
        await conn.execute(
          'UPDATE detalle_ventas SET venta_id = :venta_id, producto_id = :producto_id, '
          'precio_unitario = :precio_unitario, cantidad = :cantidad, sub_total = :sub_total, '
          'updated_at = NOW() WHERE id = :id',
          {...data, 'id': id},
        );
        return true;
      });

  /// Borra el detalle y devuelve al stock lo vendido.
  Future<IResultSet> eliminar(int id) => connection.transactional((conn) async {
        await StockProducto.devolver(conn, detalleId: id);
        return conn.execute('DELETE FROM detalle_ventas WHERE id = :id', {'id': id});
      });
}
