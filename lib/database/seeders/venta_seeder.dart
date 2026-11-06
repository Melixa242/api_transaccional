import 'package:mysql_client/mysql_client.dart';

class VentaSeeder {
  // `observaciones` identifica cada venta del seeder: DetalleVentaSeeder y
  // VentaPagoSeeder la buscan por ese texto. total = Σ detalles − descuento.
  static const _ventas = [
    {'cliente': 'Daniel Ramirez', 'fecha_venta': '2026-09-01', 'observaciones': 'Seeder: venta mostrador 1', 'opcion_pago': 'Efectivo', 'descuento': 0, 'total': 31},
    {'cliente': 'Noemi Ramirez', 'fecha_venta': '2026-09-02', 'observaciones': 'Seeder: venta mostrador 2', 'opcion_pago': 'QR', 'descuento': 0, 'total': 43},
    {'cliente': 'Marilin Toro', 'fecha_venta': '2026-09-03', 'observaciones': 'Seeder: venta pago mixto 3', 'opcion_pago': 'QR', 'descuento': 2, 'total': 30},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final venta in _ventas) {
      final existente = await connection.execute(
        'SELECT id FROM ventas WHERE observaciones = :observaciones LIMIT 1',
        {'observaciones': venta['observaciones']},
      );
      if (existente.rows.isNotEmpty) continue;

      final cliente = await connection.execute(
        'SELECT id FROM clientes WHERE nombre = :nombre LIMIT 1',
        {'nombre': venta['cliente']},
      );
      if (cliente.rows.isEmpty) {
        print('Cliente "${venta['cliente']}" no existe; venta omitida');
        continue;
      }

      await connection.execute(
        'INSERT INTO ventas (cliente_id, fecha_venta, observaciones, opcion_pago, descuento, total, estado, created_at, updated_at) '
        'VALUES (:cliente_id, :fecha_venta, :observaciones, :opcion_pago, :descuento, :total, :estado, NOW(), NOW())',
        {
          'cliente_id': cliente.rows.first.colAt(0),
          'fecha_venta': venta['fecha_venta'],
          'observaciones': venta['observaciones'],
          'opcion_pago': venta['opcion_pago'],
          'descuento': venta['descuento'],
          'total': venta['total'],
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados ventas creadas correctamente');
  }
}
