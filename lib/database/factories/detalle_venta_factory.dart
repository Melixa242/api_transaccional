import '../../models/detalle_venta.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

/// Requiere `venta_id` en los atributos al usar [create].
class DetalleVentaFactory extends Factory<DetalleVenta> {
  @override
  String get table => 'detalle_ventas';

  @override
  DetalleVenta fromRow(Map<String, dynamic> row) => DetalleVenta.fromJson(row);

  @override
  Map<String, dynamic> toRow(DetalleVenta model) => model.toJson();

  @override
  Map<String, dynamic> definition() {
    final precio = Fake.decimal(10, 120);
    final cantidad = Fake.between(1, 5).toDouble();
    return {
      'producto_id': Fake.element(Catalogos.productoIds),
      'precio_unitario': precio,
      'cantidad': cantidad,
      'sub_total': double.parse((precio * cantidad).toStringAsFixed(2)),
      'estado': 1,
    };
  }
}
