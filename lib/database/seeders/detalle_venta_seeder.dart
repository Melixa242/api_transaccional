import 'package:mysql_client/mysql_client.dart';

class DetalleVentaSeeder {
  // `venta` = observaciones de la venta creada por VentaSeeder.
  static const _detalles = [
    {'venta': 'Seeder: venta mostrador 1', 'producto': 'pollo cuarto', 'precio_unitario': 23, 'cantidad': 1},
    {'venta': 'Seeder: venta mostrador 1', 'producto': 'porcion de arroz', 'precio_unitario': 8, 'cantidad': 1},
    {'venta': 'Seeder: venta mostrador 2', 'producto': 'pollo economico', 'precio_unitario': 18, 'cantidad': 2},
    {'venta': 'Seeder: venta mostrador 2', 'producto': 'soda coca cola 500 ml', 'precio_unitario': 7, 'cantidad': 1},
    {'venta': 'Seeder: venta pago mixto 3', 'producto': 'pollo cuarto', 'precio_unitario': 23, 'cantidad': 1},
    {'venta': 'Seeder: venta pago mixto 3', 'producto': 'porcion de papa', 'precio_unitario': 9, 'cantidad': 1},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final detalle in _detalles) {
      final venta = await connection.execute(
        'SELECT id FROM ventas WHERE observaciones = :observaciones LIMIT 1',
        {'observaciones': detalle['venta']},
      );
      final producto = await connection.execute(
        'SELECT id FROM productos WHERE nombre = :nombre LIMIT 1',
        {'nombre': detalle['producto']},
      );
      if (venta.rows.isEmpty || producto.rows.isEmpty) {
        print('Venta "${detalle['venta']}" o producto "${detalle['producto']}" no existe; detalle omitido');
        continue;
      }
      final ventaId = venta.rows.first.colAt(0);
      final productoId = producto.rows.first.colAt(0);

      final existente = await connection.execute(
        'SELECT id FROM detalle_ventas WHERE venta_id = :venta_id AND producto_id = :producto_id LIMIT 1',
        {'venta_id': ventaId, 'producto_id': productoId},
      );
      if (existente.rows.isNotEmpty) continue;

      final precio = detalle['precio_unitario'] as num;
      final cantidad = detalle['cantidad'] as num;
      await connection.execute(
        'INSERT INTO detalle_ventas (venta_id, producto_id, precio_unitario, cantidad, sub_total, estado, created_at, updated_at) '
        'VALUES (:venta_id, :producto_id, :precio_unitario, :cantidad, :sub_total, :estado, NOW(), NOW())',
        {
          'venta_id': ventaId,
          'producto_id': productoId,
          'precio_unitario': precio,
          'cantidad': cantidad,
          'sub_total': precio * cantidad,
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados detalles de venta creados correctamente');
  }
}
