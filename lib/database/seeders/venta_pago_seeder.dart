import 'package:mysql_client/mysql_client.dart';

class VentaPagoSeeder {
  // `venta` = observaciones de la venta creada por VentaSeeder.
  // Los pagos de cada venta suman su total.
  static const _pagos = [
    {'venta': 'Seeder: venta mostrador 1', 'metodo_pago': 'Efectivo', 'monto': 31, 'referencia': null},
    {'venta': 'Seeder: venta mostrador 2', 'metodo_pago': 'QR', 'monto': 43, 'referencia': 'QR-SEED-0002'},
    {'venta': 'Seeder: venta pago mixto 3', 'metodo_pago': 'Efectivo', 'monto': 10, 'referencia': null},
    {'venta': 'Seeder: venta pago mixto 3', 'metodo_pago': 'QR', 'monto': 20, 'referencia': 'QR-SEED-0003'},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final pago in _pagos) {
      final venta = await connection.execute(
        'SELECT id FROM ventas WHERE observaciones = :observaciones LIMIT 1',
        {'observaciones': pago['venta']},
      );
      if (venta.rows.isEmpty) {
        print('Venta "${pago['venta']}" no existe; pago omitido');
        continue;
      }
      final ventaId = venta.rows.first.colAt(0);

      final existente = await connection.execute(
        'SELECT id FROM venta_pagos WHERE venta_id = :venta_id AND metodo_pago = :metodo_pago LIMIT 1',
        {'venta_id': ventaId, 'metodo_pago': pago['metodo_pago']},
      );
      if (existente.rows.isNotEmpty) continue;

      await connection.execute(
        'INSERT INTO venta_pagos (venta_id, metodo_pago, monto, referencia, estado, created_at, updated_at) '
        'VALUES (:venta_id, :metodo_pago, :monto, :referencia, :estado, NOW(), NOW())',
        {
          'venta_id': ventaId,
          'metodo_pago': pago['metodo_pago'],
          'monto': pago['monto'],
          'referencia': pago['referencia'],
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados pagos de venta creados correctamente');
  }
}
