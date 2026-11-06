import 'package:mysql_client/mysql_client.dart';

class OrdenProduccionSeeder {
  // numero_orden es UNIQUE: el prefijo SEED evita chocar con las órdenes reales
  // (OR-PRO-AAAA-MM-NNNN). `regla` = nombre_insumo de reglas_conversion.
  static const _ordenes = [
    {'numero_orden': 'OR-PRO-SEED-0001', 'fecha_programada': '2026-09-05', 'regla': 'Pollo Entero', 'observaciones': 'Seeder: despiece de pollo'},
    {'numero_orden': 'OR-PRO-SEED-0002', 'fecha_programada': '2026-09-06', 'regla': 'arroz', 'observaciones': 'Seeder: guarniciones del día'},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final orden in _ordenes) {
      final existente = await connection.execute(
        'SELECT id FROM orden_producciones WHERE numero_orden = :numero_orden LIMIT 1',
        {'numero_orden': orden['numero_orden']},
      );
      if (existente.rows.isNotEmpty) continue;

      // regla_conversion_id es opcional: si la regla no existe queda en NULL.
      final regla = await connection.execute(
        'SELECT id FROM reglas_conversion WHERE nombre_insumo = :nombre LIMIT 1',
        {'nombre': orden['regla']},
      );

      await connection.execute(
        'INSERT INTO orden_producciones (numero_orden, fecha_programada, regla_conversion_id, observaciones, estado, created_at, updated_at) '
        'VALUES (:numero_orden, :fecha_programada, :regla_conversion_id, :observaciones, :estado, NOW(), NOW())',
        {
          'numero_orden': orden['numero_orden'],
          'fecha_programada': orden['fecha_programada'],
          'regla_conversion_id': regla.rows.isEmpty ? null : regla.rows.first.colAt(0),
          'observaciones': orden['observaciones'],
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados órdenes de producción creadas correctamente');
  }
}
