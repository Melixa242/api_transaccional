import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `producciones` (lado servidor / shelf).
class ProduccionService {
  final DbPool connection;

  ProduccionService(this.connection);

  static const _columnas = 'id, orden_produccion_insumo_id, regla_conversion_id, producto_id, '
      'cantidad_insumo, cantidad_obtenida, nivel, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos({int? ordenProduccionInsumoId}) async {
    final result = ordenProduccionInsumoId == null
        ? await connection.execute('SELECT $_columnas FROM producciones WHERE estado = 1 ORDER BY id DESC')
        : await connection.execute(
            'SELECT $_columnas FROM producciones WHERE estado = 1 '
            'AND orden_produccion_insumo_id = :orden_produccion_insumo_id ORDER BY id',
            {'orden_produccion_insumo_id': ordenProduccionInsumoId},
          );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> insertar(Map<String, dynamic> data) => connection.execute(
        'INSERT INTO producciones (orden_produccion_insumo_id, regla_conversion_id, producto_id, '
        'cantidad_insumo, cantidad_obtenida, nivel, estado, created_at, updated_at) '
        'VALUES (:orden_produccion_insumo_id, :regla_conversion_id, :producto_id, '
        ':cantidad_insumo, :cantidad_obtenida, :nivel, 1, NOW(), NOW())',
        data,
      );

  /// Devuelve false si el registro no existe.
  Future<bool> editar(int id, Map<String, dynamic> data) async {
    await connection.execute(
      'UPDATE producciones SET orden_produccion_insumo_id = :orden_produccion_insumo_id, '
      'regla_conversion_id = :regla_conversion_id, producto_id = :producto_id, '
      'cantidad_insumo = :cantidad_insumo, cantidad_obtenida = :cantidad_obtenida, nivel = :nivel, '
      'updated_at = NOW() WHERE id = :id',
      {...data, 'id': id},
    );
    final existe = await connection.execute('SELECT 1 FROM producciones WHERE id = :id', {'id': id});
    return existe.numOfRows > 0;
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM producciones WHERE id = :id', {'id': id});
}
