import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `ingreso_bebida_producto` (lado servidor / shelf).
class IngresoBebidaProductoService {
  final DbPool connection;

  IngresoBebidaProductoService(this.connection);

  static const _columnas = 'id, ingreso_bebida_id, producto_id, cantidad_ingresa, precio, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos({int? ingresoBebidaId}) async {
    final result = ingresoBebidaId == null
        ? await connection.execute('SELECT $_columnas FROM ingreso_bebida_producto WHERE estado = 1 ORDER BY id DESC')
        : await connection.execute(
            'SELECT $_columnas FROM ingreso_bebida_producto WHERE estado = 1 '
            'AND ingreso_bebida_id = :ingreso_bebida_id ORDER BY id',
            {'ingreso_bebida_id': ingresoBebidaId},
          );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> insertar(Map<String, dynamic> data) => connection.execute(
        'INSERT INTO ingreso_bebida_producto (ingreso_bebida_id, producto_id, cantidad_ingresa, precio, estado, created_at, updated_at) '
        'VALUES (:ingreso_bebida_id, :producto_id, :cantidad_ingresa, :precio, 1, NOW(), NOW())',
        data,
      );

  /// Devuelve false si el registro no existe.
  Future<bool> editar(int id, Map<String, dynamic> data) async {
    await connection.execute(
      'UPDATE ingreso_bebida_producto SET ingreso_bebida_id = :ingreso_bebida_id, producto_id = :producto_id, '
      'cantidad_ingresa = :cantidad_ingresa, precio = :precio, updated_at = NOW() WHERE id = :id',
      {...data, 'id': id},
    );
    final existe = await connection.execute('SELECT 1 FROM ingreso_bebida_producto WHERE id = :id', {'id': id});
    return existe.numOfRows > 0;
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM ingreso_bebida_producto WHERE id = :id', {'id': id});
}
