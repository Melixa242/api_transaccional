import 'package:proyecto_krosty/database/database.dart';

import 'package:proyecto_krosty/database/seeders/venta_seeder.dart';
import 'package:proyecto_krosty/database/seeders/detalle_venta_seeder.dart';
import 'package:proyecto_krosty/database/seeders/venta_pago_seeder.dart';
import 'package:proyecto_krosty/database/seeders/ingreso_insumo_seeder.dart';
import 'package:proyecto_krosty/database/seeders/ingreso_insumo_detalle_seeder.dart';
import 'package:proyecto_krosty/database/seeders/ingreso_bebida_seeder.dart';
import 'package:proyecto_krosty/database/seeders/ingreso_bebida_producto_seeder.dart';
import 'package:proyecto_krosty/database/seeders/orden_produccion_seeder.dart';
import 'package:proyecto_krosty/database/seeders/orden_produccion_insumo_seeder.dart';
import 'package:proyecto_krosty/database/seeders/produccion_seeder.dart';
import 'package:proyecto_krosty/database/seeders/merma_seeder.dart';

// Ejecutar con: dart run bin/seed.dart
// Orden pensado para respetar las llaves foráneas (cabeceras primero,
// luego sus detalles). Los catálogos (clientes, productos, insumos,
// reglas_conversion) los carga Laravel; los seeders los buscan por nombre.
// Cada seeder omite lo que ya existe, así que se puede correr varias veces.
void main() async {
  final connection = await Database.connect();

  await VentaSeeder.run(connection);
  await DetalleVentaSeeder.run(connection);
  await VentaPagoSeeder.run(connection);
  await IngresoInsumoSeeder.run(connection);
  await IngresoInsumoDetalleSeeder.run(connection);
  await IngresoBebidaSeeder.run(connection);
  await IngresoBebidaProductoSeeder.run(connection);
  await OrdenProduccionSeeder.run(connection);
  await OrdenProduccionInsumoSeeder.run(connection);
  await ProduccionSeeder.run(connection);
  await MermaSeeder.run(connection);

  await connection.close();
  print('Seeders ejecutados correctamente');
}
