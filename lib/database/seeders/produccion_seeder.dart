import 'package:mysql_client/mysql_client.dart';

class ProduccionSeeder {
  // Una producción por insumo de orden (`orden` + `insumo` de OrdenProduccionInsumoSeeder).
  // cantidad_obtenida va en unidades del producto, según la regla
  // (1 pollo entero ≈ 8 piezas, 1 kg arroz ≈ 9-10 porciones, 1 kg papa ≈ 35-40 porciones).
  static const _producciones = [
    {'orden': 'OR-PRO-SEED-0001', 'insumo': 'Pollo Entero', 'regla': 'Pollo Entero', 'producto': 'pollo piezas', 'cantidad_insumo': 10, 'cantidad_obtenida': 78, 'nivel': 0},
    {'orden': 'OR-PRO-SEED-0002', 'insumo': 'arroz', 'regla': 'arroz', 'producto': 'porcion de arroz', 'cantidad_insumo': 5, 'cantidad_obtenida': 48, 'nivel': 0},
    {'orden': 'OR-PRO-SEED-0002', 'insumo': 'Papa', 'regla': 'Papa', 'producto': 'porcion de papa', 'cantidad_insumo': 8, 'cantidad_obtenida': 290, 'nivel': 0},
  ];

  static Future<void> run(MySQLConnection connection) async {
    var creados = 0;
    for (final item in _producciones) {
      final ordenInsumo = await connection.execute(
        'SELECT oi.id FROM orden_produccion_insumo oi '
        'JOIN orden_producciones o ON o.id = oi.orden_produccion_id '
        'JOIN insumos i ON i.id = oi.insumo_id '
        'WHERE o.numero_orden = :orden AND i.nombre = :insumo LIMIT 1',
        {'orden': item['orden'], 'insumo': item['insumo']},
      );
      if (ordenInsumo.rows.isEmpty) {
        print('Insumo "${item['insumo']}" de la orden "${item['orden']}" no existe; producción omitida');
        continue;
      }
      final ordenInsumoId = ordenInsumo.rows.first.colAt(0);

      // orden_produccion_insumo_id es UNIQUE: una producción por insumo de orden.
      final existente = await connection.execute(
        'SELECT id FROM producciones WHERE orden_produccion_insumo_id = :id LIMIT 1',
        {'id': ordenInsumoId},
      );
      if (existente.rows.isNotEmpty) continue;

      final regla = await connection.execute(
        'SELECT id FROM reglas_conversion WHERE nombre_insumo = :nombre LIMIT 1',
        {'nombre': item['regla']},
      );
      final producto = await connection.execute(
        'SELECT id FROM productos WHERE nombre = :nombre LIMIT 1',
        {'nombre': item['producto']},
      );

      await connection.execute(
        'INSERT INTO producciones (orden_produccion_insumo_id, regla_conversion_id, producto_id, cantidad_insumo, '
        'cantidad_obtenida, nivel, estado, created_at, updated_at) '
        'VALUES (:orden_produccion_insumo_id, :regla_conversion_id, :producto_id, :cantidad_insumo, '
        ':cantidad_obtenida, :nivel, :estado, NOW(), NOW())',
        {
          'orden_produccion_insumo_id': ordenInsumoId,
          'regla_conversion_id': regla.rows.isEmpty ? null : regla.rows.first.colAt(0),
          'producto_id': producto.rows.isEmpty ? null : producto.rows.first.colAt(0),
          'cantidad_insumo': item['cantidad_insumo'],
          'cantidad_obtenida': item['cantidad_obtenida'],
          'nivel': item['nivel'],
          'estado': 1,
        },
      );
      creados++;
    }
    print('$creados producciones creadas correctamente');
  }
}
