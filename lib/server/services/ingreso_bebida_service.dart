import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `ingreso_bebidas` y sus productos (lado servidor / shelf).
class IngresoBebidaService {
  final DbPool connection;

  IngresoBebidaService(this.connection);

  static const _columnas = 'id, nombre, descripcion, fecha_ingreso, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos() async {
    final result = await connection.execute(
      'SELECT $_columnas FROM ingreso_bebidas WHERE estado = 1 ORDER BY fecha_ingreso DESC, id DESC',
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> buscar(String query) async {
    final result = await connection.execute(
      'SELECT $_columnas FROM ingreso_bebidas '
      'WHERE estado = 1 AND (nombre LIKE :q OR descripcion LIKE :q OR fecha_ingreso LIKE :q) '
      'ORDER BY fecha_ingreso DESC, id DESC',
      {'q': '%$query%'},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> productos(int ingresoBebidaId) async {
    final result = await connection.execute(
      'SELECT id, producto_id, cantidad_ingresa, precio FROM ingreso_bebida_producto '
      'WHERE ingreso_bebida_id = :id AND estado = 1',
      {'id': ingresoBebidaId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  /// Inserta cabecera + productos en una transacción. Devuelve el id creado.
  Future<int> insertar(Map<String, dynamic> ingreso, List<Map<String, dynamic>> productos) {
    return connection.transactional((conn) async {
      final result = await conn.execute(
        'INSERT INTO ingreso_bebidas (nombre, descripcion, fecha_ingreso, estado, created_at, updated_at) '
        'VALUES (:nombre, :descripcion, :fecha_ingreso, 1, NOW(), NOW())',
        ingreso,
      );
      final id = result.lastInsertID.toInt();
      await _insertarProductos(conn, id, productos);
      return id;
    });
  }

  /// Actualiza la cabecera y reemplaza sus productos. Devuelve 0 si no existe.
  Future<int> editar(int id, Map<String, dynamic> ingreso, List<Map<String, dynamic>> productos) {
    return connection.transactional((conn) async {
      final existe = await conn.execute('SELECT 1 FROM ingreso_bebidas WHERE id = :id', {'id': id});
      if (existe.numOfRows == 0) return 0;

      await conn.execute(
        'UPDATE ingreso_bebidas SET nombre = :nombre, descripcion = :descripcion, '
        'fecha_ingreso = :fecha_ingreso, updated_at = NOW() WHERE id = :id',
        {...ingreso, 'id': id},
      );
      await conn.execute('DELETE FROM ingreso_bebida_producto WHERE ingreso_bebida_id = :id', {'id': id});
      await _insertarProductos(conn, id, productos);
      return 1;
    });
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM ingreso_bebidas WHERE id = :id', {'id': id});

  Future<void> _insertarProductos(MySQLConnection conn, int ingresoId, List<Map<String, dynamic>> productos) async {
    for (final p in productos) {
      await conn.execute(
        'INSERT INTO ingreso_bebida_producto (ingreso_bebida_id, producto_id, cantidad_ingresa, precio, estado, created_at, updated_at) '
        'VALUES (:ingreso_bebida_id, :producto_id, :cantidad_ingresa, :precio, 1, NOW(), NOW())',
        {...p, 'ingreso_bebida_id': ingresoId},
      );
    }
  }
}
