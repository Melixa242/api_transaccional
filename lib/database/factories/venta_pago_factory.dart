import '../../models/venta_pago.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

/// Requiere `venta_id` en los atributos al usar [create].
class VentaPagoFactory extends Factory<VentaPago> {
  @override
  String get table => 'venta_pagos';

  @override
  VentaPago fromRow(Map<String, dynamic> row) => VentaPago.fromJson(row);

  @override
  Map<String, dynamic> toRow(VentaPago model) => model.toRow();

  @override
  Map<String, dynamic> definition() {
    final metodo = Fake.element(Catalogos.metodosPago);
    return {
      'metodo_pago': metodo,
      'monto': Fake.decimal(20, 500),
      'referencia': metodo == 'Efectivo' ? null : Fake.digits(8),
      'estado': 1,
    };
  }
}
