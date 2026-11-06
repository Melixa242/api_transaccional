import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `ingreso_insumos` y su detalle (lado servidor / shelf).
class IngresoInsumoService {
  final DbPool connection;

  IngresoInsumoService(this.connection);

  Future<List<Map<String, dynamic>>> obtenerTodos() async {
    final result = await connection.execute(
      'SELECT id, fecha_ingreso, descripcion, estado FROM ingreso_insumos '
      'WHERE estado = 1 ORDER BY fecha_ingreso DESC, id DESC',
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> buscar(String query) async {
    final result = await connection.execute(
      'SELECT id, fecha_ingreso, descripcion, estado FROM ingreso_insumos '
      'WHERE estado = 1 AND (descripcion LIKE :q OR fecha_ingreso LIKE :q) '
      'ORDER BY fecha_ingreso DESC, id DESC',
      {'q': '%$query%'},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> detalles(int ingresoInsumoId) async {
    final result = await connection.execute(
      'SELECT id, insumo_id, cantidad, precio_unitario FROM ingreso_insumo_detalle '
      'WHERE ingreso_insumo_id = :id AND estado = 1',
      {'id': ingresoInsumoId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  /// Inserta cabecera + detalles en una transacción. Devuelve el id creado.
  Future<int> insertar(String fechaIngreso, String? descripcion, List<Map<String, dynamic>> detalles) {
    return connection.transactional((conn) async {
      final result = await conn.execute(
        'INSERT INTO ingreso_insumos (fecha_ingreso, descripcion, estado, created_at, updated_at) VALUES (:fecha, :descripcion, 1, NOW(), NOW())',
        {'fecha': fechaIngreso, 'descripcion': descripcion},
      );
      final id = result.lastInsertID.toInt();
      await _insertarDetalles(conn, id, detalles);
      return id;
    });
  }

  /// Actualiza la cabecera y reemplaza sus detalles. Devuelve filas afectadas.
  Future<int> editar(int id, String fechaIngreso, String? descripcion, List<Map<String, dynamic>> detalles) {
    return connection.transactional((conn) async {
      final result = await conn.execute(
        'UPDATE ingreso_insumos SET fecha_ingreso = :fecha, descripcion = :descripcion, updated_at = NOW() WHERE id = :id',
        {'id': id, 'fecha': fechaIngreso, 'descripcion': descripcion},
      );
      if (result.affectedRows == BigInt.zero) {
        // MySQL cuenta 0 si los valores no cambiaron: confirmar que existe.
        final existe = await conn.execute('SELECT 1 FROM ingreso_insumos WHERE id = :id', {'id': id});
        if (existe.numOfRows == 0) return 0;
      }
      await conn.execute('DELETE FROM ingreso_insumo_detalle WHERE ingreso_insumo_id = :id', {'id': id});
      await _insertarDetalles(conn, id, detalles);
      return 1;
    });
  }

  Future<IResultSet> eliminar(int id) => connection.execute(
        'DELETE FROM ingreso_insumos WHERE id = :id',
        {'id': id},
      );

  Future<void> _insertarDetalles(MySQLConnection conn, int ingresoId, List<Map<String, dynamic>> detalles) async {
    for (final d in detalles) {
      await conn.execute(
        'INSERT INTO ingreso_insumo_detalle (ingreso_insumo_id, insumo_id, cantidad, precio_unitario, estado, created_at, updated_at) '
        'VALUES (:ingreso, :insumo, :cantidad, :precio, 1, NOW(), NOW())',
        {
          'ingreso': ingresoId,
          'insumo': d['insumo_id'],
          'cantidad': d['cantidad'],
          'precio': d['precio_unitario'],
        },
      );
    }
  }
}
