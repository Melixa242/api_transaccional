import 'package:mysql_client/mysql_client.dart';

class IngresoInsumoDetalleSeeder {
  // `ingreso` = descripcion del ingreso creado por IngresoInsumoSeeder.
  static const _detalles = [
    {'ingreso': 'Seeder: compra semanal de pollo', 'insumo': 'Pollo Entero', 'cantidad': 20, 'precio_unitario': 45},
    {'ingreso': 'Seeder: compra semanal de pollo', 'insumo': 'Aceite', 'cantidad': 5, 'precio_unitario': 18},
    {'ingreso': 'Seeder: compra de abarrotes', 'insumo': 'arroz', 'cantidad': 25, 'precio_unitario': 7.5},
    {'ingreso': 'Seeder: compra de abarrotes', 'insumo': 'Papa', 'cantidad': 50, 'precio_unitario': 3},
    {'ingreso': 'Seeder: compra de abarrotes', 'insumo': 'Sal', 'cantidad': 2, 'precio_unitario': 2.5},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final detalle in _detalles) {
      final ingreso = await connection.execute(
        'SELECT id FROM ingreso_insumos WHERE descripcion = :descripcion LIMIT 1',
        {'descripcion': detalle['ingreso']},
      );
      final insumo = await connection.execute(
        'SELECT id FROM insumos WHERE nombre = :nombre LIMIT 1',
        {'nombre': detalle['insumo']},
      );
      if (ingreso.rows.isEmpty || insumo.rows.isEmpty) {
        print('Ingreso "${detalle['ingreso']}" o insumo "${detalle['insumo']}" no existe; detalle omitido');
        continue;
      }
      final ingresoId = ingreso.rows.first.colAt(0);
      final insumoId = insumo.rows.first.colAt(0);

      // (ingreso_insumo_id, insumo_id) es UNIQUE.
      final existente = await connection.execute(
        'SELECT id FROM ingreso_insumo_detalle WHERE ingreso_insumo_id = :ingreso_id AND insumo_id = :insumo_id LIMIT 1',
        {'ingreso_id': ingresoId, 'insumo_id': insumoId},
      );
      if (existente.rows.isNotEmpty) continue;

      await connection.execute(
        'INSERT INTO ingreso_insumo_detalle (ingreso_insumo_id, insumo_id, cantidad, precio_unitario, estado, created_at, updated_at) '
        'VALUES (:ingreso_insumo_id, :insumo_id, :cantidad, :precio_unitario, :estado, NOW(), NOW())',
        {
          'ingreso_insumo_id': ingresoId,
          'insumo_id': insumoId,
          'cantidad': detalle['cantidad'],
          'precio_unitario': detalle['precio_unitario'],
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados detalles de ingreso de insumos creados correctamente');
  }
}
