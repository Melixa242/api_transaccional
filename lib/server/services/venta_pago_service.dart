import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Acceso MySQL a `venta_pagos` (lado servidor / shelf).
class VentaPagoService {
  final DbPool connection;

  VentaPagoService(this.connection);

  static const _columnas = 'id, venta_id, metodo_pago, monto, referencia, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos({int? ventaId}) async {
    final result = ventaId == null
        ? await connection.execute('SELECT $_columnas FROM venta_pagos WHERE estado = 1 ORDER BY id DESC')
        : await connection.execute(
            'SELECT $_columnas FROM venta_pagos WHERE estado = 1 AND venta_id = :venta_id ORDER BY id',
            {'venta_id': ventaId},
          );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<IResultSet> insertar(Map<String, dynamic> data) => connection.execute(
        'INSERT INTO venta_pagos (venta_id, metodo_pago, monto, referencia, estado, created_at, updated_at) '
        'VALUES (:venta_id, :metodo_pago, :monto, :referencia, 1, NOW(), NOW())',
        data,
      );

  /// Devuelve false si el registro no existe.
  Future<bool> editar(int id, Map<String, dynamic> data) async {
    await connection.execute(
      'UPDATE venta_pagos SET venta_id = :venta_id, metodo_pago = :metodo_pago, monto = :monto, '
      'referencia = :referencia, updated_at = NOW() WHERE id = :id',
      {...data, 'id': id},
    );
    final existe = await connection.execute('SELECT 1 FROM venta_pagos WHERE id = :id', {'id': id});
    return existe.numOfRows > 0;
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM venta_pagos WHERE id = :id', {'id': id});
}
