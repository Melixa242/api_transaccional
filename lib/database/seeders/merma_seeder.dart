import 'package:mysql_client/mysql_client.dart';

class MermaSeeder {
  // La producción se identifica por `orden` + `insumo` (ProduccionSeeder).
  // `cantidad` va en unidades del producto obtenido.
  static const _mermas = [
    {'orden': 'OR-PRO-SEED-0001', 'insumo': 'Pollo Entero', 'cantidad': 2},
    {'orden': 'OR-PRO-SEED-0002', 'insumo': 'Papa', 'cantidad': 10},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final merma in _mermas) {
      final produccion = await connection.execute(
        'SELECT p.id FROM producciones p '
        'JOIN orden_produccion_insumo oi ON oi.id = p.orden_produccion_insumo_id '
        'JOIN orden_producciones o ON o.id = oi.orden_produccion_id '
        'JOIN insumos i ON i.id = oi.insumo_id '
        'WHERE o.numero_orden = :orden AND i.nombre = :insumo LIMIT 1',
        {'orden': merma['orden'], 'insumo': merma['insumo']},
      );
      if (produccion.rows.isEmpty) {
        print('Producción de "${merma['insumo']}" en "${merma['orden']}" no existe; merma omitida');
        continue;
      }
      final produccionId = produccion.rows.first.colAt(0);

      final existente = await connection.execute(
        'SELECT id FROM mermas WHERE produccion_id = :produccion_id LIMIT 1',
        {'produccion_id': produccionId},
      );
      if (existente.rows.isNotEmpty) continue;

      await connection.execute(
        'INSERT INTO mermas (produccion_id, cantidad, estado, created_at, updated_at) '
        'VALUES (:produccion_id, :cantidad, :estado, NOW(), NOW())',
        {'produccion_id': produccionId, 'cantidad': merma['cantidad'], 'estado': 1},
      );
      creados++;
    }
    print('$creados mermas creadas correctamente');
  }
}
