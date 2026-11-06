import 'package:mysql_client/mysql_client.dart';

class IngresoBebidaProductoSeeder {
  // `ingreso` = nombre del ingreso creado por IngresoBebidaSeeder.
  static const _productos = [
    {'ingreso': 'Seeder: reposición de gaseosas', 'producto': 'soda fanta 300ml', 'cantidad_ingresa': 24, 'precio': 3.5},
    {'ingreso': 'Seeder: reposición de gaseosas', 'producto': 'soda coca cola 500 ml', 'cantidad_ingresa': 24, 'precio': 5},
    {'ingreso': 'Seeder: reposición fin de semana', 'producto': 'soda coca cola 500 ml', 'cantidad_ingresa': 12, 'precio': 5},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final item in _productos) {
      final ingreso = await connection.execute(
        'SELECT id FROM ingreso_bebidas WHERE nombre = :nombre LIMIT 1',
        {'nombre': item['ingreso']},
      );
      final producto = await connection.execute(
        'SELECT id FROM productos WHERE nombre = :nombre LIMIT 1',
        {'nombre': item['producto']},
      );
      if (ingreso.rows.isEmpty || producto.rows.isEmpty) {
        print('Ingreso "${item['ingreso']}" o producto "${item['producto']}" no existe; producto omitido');
        continue;
      }
      final ingresoId = ingreso.rows.first.colAt(0);
      final productoId = producto.rows.first.colAt(0);

      final existente = await connection.execute(
        'SELECT id FROM ingreso_bebida_producto WHERE ingreso_bebida_id = :ingreso_id AND producto_id = :producto_id LIMIT 1',
        {'ingreso_id': ingresoId, 'producto_id': productoId},
      );
      if (existente.rows.isNotEmpty) continue;

      await connection.execute(
        'INSERT INTO ingreso_bebida_producto (ingreso_bebida_id, producto_id, cantidad_ingresa, precio, estado, created_at, updated_at) '
        'VALUES (:ingreso_bebida_id, :producto_id, :cantidad_ingresa, :precio, :estado, NOW(), NOW())',
        {
          'ingreso_bebida_id': ingresoId,
          'producto_id': productoId,
          'cantidad_ingresa': item['cantidad_ingresa'],
          'precio': item['precio'],
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados productos de ingreso de bebidas creados correctamente');
  }
}
