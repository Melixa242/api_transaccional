import 'dart:io';
import 'package:proyecto_krosty/database/database.dart';

Future<void> main() async {
  print('Conectando a la base de datos...');

  final connection = await Database.connect();

  try {
    print('Conexión establecida.');

    // `migrations` es la tabla de Laravel (con columna batch NOT NULL):
    // este script lleva su propio control para no chocar con ella.
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS dart_migrations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        migration VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    final migrationsDirectory = Directory(
      'lib/database/migrations',
    );

    final files = migrationsDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .toList();

    const migrationPriority = {
      '001_create_ventas_table.sql': 1,
      '002_create_detalle_ventas_table.sql': 2,
      '003_create_venta_pagos_table.sql': 3,
      '004_create_ingreso_insumos_table.sql': 4,
      '005_create_ingreso_insumo_detalle_table.sql': 5,
      '006_create_ingreso_bebidas_table.sql': 6,
      '007_create_ingreso_bebida_producto_table.sql': 7,
      '008_create_orden_producciones_table.sql': 8,
      '009_create_orden_produccion_insumo_table.sql': 9,
      '010_create_producciones_table.sql': 10,
      '011_create_mermas_table.sql': 11,
    };
    files.sort((a, b) {
      final aName = a.uri.pathSegments.last;
      final bName = b.uri.pathSegments.last;
      return (migrationPriority[aName] ?? 1000).compareTo(migrationPriority[bName] ?? 1000);
    });

    for (final file in files) {
      final migrationName = file.uri.pathSegments.last;

      final result = await connection.execute(
        'SELECT id FROM dart_migrations WHERE migration = :migration',
        {'migration': migrationName},
      );

      if (result.rows.isNotEmpty) {
        print('$migrationName ya ejecutada');
        continue;
      }

      final sql = await file.readAsString();

      await connection.execute(sql);

      await connection.execute(
        'INSERT INTO dart_migrations (migration) VALUES (:migration)',
        {'migration': migrationName},
      );

      print('$migrationName ejecutada');
    }

    print('\nMigraciones completadas.');
  } finally {
    await connection.close();
  }
}
