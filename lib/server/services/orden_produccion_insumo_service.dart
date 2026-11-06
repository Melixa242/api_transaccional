import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `orden_produccion_insumo` (lado servidor / shelf).
class OrdenProduccionInsumoService {
  final DbPool connection;

  OrdenProduccionInsumoService(this.connection);

  static const _columnas = 'id, orden_produccion_id, insumo_id, cantidad, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos({int? ordenProduccionId}) async {
    final result = ordenProduccionId == null
        ? await connection.execute('SELECT $_columnas FROM orden_produccion_insumo WHERE estado = 1 ORDER BY id DESC')
        : await connection.execute(
            'SELECT $_columnas FROM orden_produccion_insumo WHERE estado = 1 '
            'AND orden_produccion_id = :orden_produccion_id ORDER BY id',
            {'orden_produccion_id': ordenProduccionId},
          );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> insertar(Map<String, dynamic> data) => connection.execute(
        'INSERT INTO orden_produccion_insumo (orden_produccion_id, insumo_id, cantidad, estado, created_at, updated_at) '
        'VALUES (:orden_produccion_id, :insumo_id, :cantidad, 1, NOW(), NOW())',
        data,
      );

  /// Devuelve false si el registro no existe.
  Future<bool> editar(int id, Map<String, dynamic> data) async {
    await connection.execute(
      'UPDATE orden_produccion_insumo SET orden_produccion_id = :orden_produccion_id, insumo_id = :insumo_id, '
      'cantidad = :cantidad, updated_at = NOW() WHERE id = :id',
      {...data, 'id': id},
    );
    final existe = await connection.execute('SELECT 1 FROM orden_produccion_insumo WHERE id = :id', {'id': id});
    return existe.numOfRows > 0;
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM orden_produccion_insumo WHERE id = :id', {'id': id});
}
