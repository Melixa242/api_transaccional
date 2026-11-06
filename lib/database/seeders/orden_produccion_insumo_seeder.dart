import 'package:mysql_client/mysql_client.dart';

class OrdenProduccionInsumoSeeder {
  // `orden` = numero_orden creado por OrdenProduccionSeeder.
  static const _insumos = [
    {'orden': 'OR-PRO-SEED-0001', 'insumo': 'Pollo Entero', 'cantidad': 10},
    {'orden': 'OR-PRO-SEED-0002', 'insumo': 'arroz', 'cantidad': 5},
    {'orden': 'OR-PRO-SEED-0002', 'insumo': 'Papa', 'cantidad': 8},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final item in _insumos) {
      final orden = await connection.execute(
        'SELECT id FROM orden_producciones WHERE numero_orden = :numero_orden LIMIT 1',
        {'numero_orden': item['orden']},
      );
      final insumo = await connection.execute(
        'SELECT id FROM insumos WHERE nombre = :nombre LIMIT 1',
        {'nombre': item['insumo']},
      );
      if (orden.rows.isEmpty || insumo.rows.isEmpty) {
        print('Orden "${item['orden']}" o insumo "${item['insumo']}" no existe; insumo omitido');
        continue;
      }
      final ordenId = orden.rows.first.colAt(0);
      final insumoId = insumo.rows.first.colAt(0);

      final existente = await connection.execute(
        'SELECT id FROM orden_produccion_insumo WHERE orden_produccion_id = :orden_id AND insumo_id = :insumo_id LIMIT 1',
        {'orden_id': ordenId, 'insumo_id': insumoId},
      );
      if (existente.rows.isNotEmpty) continue;

      await connection.execute(
        'INSERT INTO orden_produccion_insumo (orden_produccion_id, insumo_id, cantidad, estado, created_at, updated_at) '
        'VALUES (:orden_produccion_id, :insumo_id, :cantidad, :estado, NOW(), NOW())',
        {
          'orden_produccion_id': ordenId,
          'insumo_id': insumoId,
          'cantidad': item['cantidad'],
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados insumos de órdenes de producción creados correctamente');
  }
}
