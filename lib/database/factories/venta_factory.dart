import '../../models/venta.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

class VentaFactory extends Factory<Venta> {
  @override
  String get table => 'ventas';

  @override
  Venta fromRow(Map<String, dynamic> row) => Venta.fromJson(row);

  @override
  Map<String, dynamic> toRow(Venta model) => model.toRow();

  @override
  Map<String, dynamic> definition() => {
        'cliente_id': Fake.element(Catalogos.clienteIds),
        'fecha_venta': Fake.pastDate(),
        'observaciones': Fake.chance(30) ? Fake.sentence() : null,
        'opcion_pago': Fake.element(Catalogos.metodosPago),
        'descuento': 0,
        'total': Fake.decimal(20, 500),
        'estado': 1,
      };
}
