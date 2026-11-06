import '../../models/orden_produccion_insumo.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

/// Requiere `orden_produccion_id` en los atributos al usar [create].
class OrdenProduccionInsumoFactory extends Factory<OrdenProduccionInsumo> {
  @override
  String get table => 'orden_produccion_insumo';

  @override
  OrdenProduccionInsumo fromRow(Map<String, dynamic> row) => OrdenProduccionInsumo.fromJson(row);

  @override
  Map<String, dynamic> toRow(OrdenProduccionInsumo model) => model.toRow();

  @override
  Map<String, dynamic> definition() => {
        'insumo_id': Fake.element(Catalogos.insumoIds),
        'cantidad': Fake.decimal(10, 100),
        'estado': 1,
      };
}
