import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `mermas` (lado servidor / shelf).
class MermaService {
  final DbPool connection;

  MermaService(this.connection);

  static const _columnas = 'id, produccion_id, cantidad, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos({int? produccionId}) async {
    final result = produccionId == null
        ? await connection.execute('SELECT $_columnas FROM mermas WHERE estado = 1 ORDER BY id DESC')
        : await connection.execute(
            'SELECT $_columnas FROM mermas WHERE estado = 1 AND produccion_id = :produccion_id ORDER BY id',
            {'produccion_id': produccionId},
          );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> insertar(Map<String, dynamic> data) => connection.execute(
        'INSERT INTO mermas (produccion_id, cantidad, estado, created_at, updated_at) '
        'VALUES (:produccion_id, :cantidad, 1, NOW(), NOW())',
        data,
      );

  /// Devuelve false si el registro no existe.
  Future<bool> editar(int id, Map<String, dynamic> data) async {
    await connection.execute(
      'UPDATE mermas SET produccion_id = :produccion_id, cantidad = :cantidad, updated_at = NOW() WHERE id = :id',
      {...data, 'id': id},
    );
    final existe = await connection.execute('SELECT 1 FROM mermas WHERE id = :id', {'id': id});
    return existe.numOfRows > 0;
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM mermas WHERE id = :id', {'id': id});
}
