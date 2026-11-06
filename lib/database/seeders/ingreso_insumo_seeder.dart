import 'package:mysql_client/mysql_client.dart';

class IngresoInsumoSeeder {
  // `descripcion` identifica cada ingreso (IngresoInsumoDetalleSeeder lo busca por ella).
  static const _ingresos = [
    {'fecha_ingreso': '2026-09-01', 'descripcion': 'Seeder: compra semanal de pollo'},
    {'fecha_ingreso': '2026-09-02', 'descripcion': 'Seeder: compra de abarrotes'},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final ingreso in _ingresos) {
      final existente = await connection.execute(
        'SELECT id FROM ingreso_insumos WHERE descripcion = :descripcion LIMIT 1',
        {'descripcion': ingreso['descripcion']},
      );
      if (existente.rows.isNotEmpty) continue;

      await connection.execute(
        'INSERT INTO ingreso_insumos (fecha_ingreso, descripcion, estado, created_at, updated_at) '
        'VALUES (:fecha_ingreso, :descripcion, :estado, NOW(), NOW())',
        {...ingreso, 'estado': 1},
      );
      creados++;
    }
    print('$creados ingresos de insumos creados correctamente');
  }
}
