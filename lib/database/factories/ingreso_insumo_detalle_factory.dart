import '../../models/ingreso_insumo_detalle.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

/// Requiere `ingreso_insumo_id` en los atributos al usar [create].
/// Ojo: (ingreso_insumo_id, insumo_id) es UNIQUE.
class IngresoInsumoDetalleFactory extends Factory<IngresoInsumoDetalle> {
  @override
  String get table => 'ingreso_insumo_detalle';

  @override
  IngresoInsumoDetalle fromRow(Map<String, dynamic> row) => IngresoInsumoDetalle.fromJson(row);

  @override
  Map<String, dynamic> toRow(IngresoInsumoDetalle model) => model.toRow();

  @override
  Map<String, dynamic> definition() => {
        'insumo_id': Fake.element(Catalogos.insumoIds),
        'cantidad': Fake.decimal(5, 200),
        'precio_unitario': Fake.decimal(2, 60),
        'estado': 1,
      };
}
