import '../../models/ingreso_bebida_producto.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

/// Requiere `ingreso_bebida_id` en los atributos al usar [create].
class IngresoBebidaProductoFactory extends Factory<IngresoBebidaProducto> {
  @override
  String get table => 'ingreso_bebida_producto';

  @override
  IngresoBebidaProducto fromRow(Map<String, dynamic> row) => IngresoBebidaProducto.fromJson(row);

  @override
  Map<String, dynamic> toRow(IngresoBebidaProducto model) => model.toJson();

  @override
  Map<String, dynamic> definition() => {
        'producto_id': Fake.element(Catalogos.bebidaIds),
        'cantidad_ingresa': Fake.between(6, 48).toDouble(),
        'precio': Fake.decimal(5, 25),
        'estado': 1,
      };
}
