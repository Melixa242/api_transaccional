import 'package:mysql_client/mysql_client.dart';

class IngresoBebidaSeeder {
  // `nombre` identifica cada ingreso (IngresoBebidaProductoSeeder lo busca por él).
  static const _ingresos = [
    {'nombre': 'Seeder: reposición de gaseosas', 'descripcion': 'Proveedor de bebidas', 'fecha_ingreso': '2026-09-01'},
    {'nombre': 'Seeder: reposición fin de semana', 'descripcion': null, 'fecha_ingreso': '2026-09-05'},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final ingreso in _ingresos) {
      final existente = await connection.execute(
        'SELECT id FROM ingreso_bebidas WHERE nombre = :nombre LIMIT 1',
        {'nombre': ingreso['nombre']},
      );
      if (existente.rows.isNotEmpty) continue;

      await connection.execute(
        'INSERT INTO ingreso_bebidas (nombre, descripcion, fecha_ingreso, estado, created_at, updated_at) '
        'VALUES (:nombre, :descripcion, :fecha_ingreso, :estado, NOW(), NOW())',
        {...ingreso, 'estado': 1},
      );
      creados++;
    }
    print('$creados ingresos de bebidas creados correctamente');
  }
}
