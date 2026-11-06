import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `ingreso_insumo_detalle` (lado servidor / shelf).
class IngresoInsumoDetalleService {
  final DbPool connection;

  IngresoInsumoDetalleService(this.connection);

  static const _columnas = 'id, ingreso_insumo_id, insumo_id, cantidad, precio_unitario, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos({int? ingresoInsumoId}) async {
    final result = ingresoInsumoId == null
        ? await connection.execute('SELECT $_columnas FROM ingreso_insumo_detalle WHERE estado = 1 ORDER BY id DESC')
        : await connection.execute(
            'SELECT $_columnas FROM ingreso_insumo_detalle WHERE estado = 1 AND ingreso_insumo_id = :ingreso_insumo_id ORDER BY id',
            {'ingreso_insumo_id': ingresoInsumoId},
          );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> insertar(Map<String, dynamic> data) => connection.execute(
        'INSERT INTO ingreso_insumo_detalle (ingreso_insumo_id, insumo_id, cantidad, precio_unitario, estado, created_at, updated_at) '
        'VALUES (:ingreso_insumo_id, :insumo_id, :cantidad, :precio_unitario, 1, NOW(), NOW())',
        data,
      );

  /// Devuelve false si el registro no existe.
  Future<bool> editar(int id, Map<String, dynamic> data) async {
    await connection.execute(
      'UPDATE ingreso_insumo_detalle SET ingreso_insumo_id = :ingreso_insumo_id, insumo_id = :insumo_id, '
      'cantidad = :cantidad, precio_unitario = :precio_unitario, updated_at = NOW() WHERE id = :id',
      {...data, 'id': id},
    );
    final existe = await connection.execute('SELECT 1 FROM ingreso_insumo_detalle WHERE id = :id', {'id': id});
    return existe.numOfRows > 0;
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM ingreso_insumo_detalle WHERE id = :id', {'id': id});
}
