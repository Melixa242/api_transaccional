import '../../models/ingreso_insumo.dart';
import 'factory.dart';
import 'fake.dart';

class IngresoInsumoFactory extends Factory<IngresoInsumo> {
  @override
  String get table => 'ingreso_insumos';

  @override
  IngresoInsumo fromRow(Map<String, dynamic> row) => IngresoInsumo.fromJson(row);

  @override
  Map<String, dynamic> toRow(IngresoInsumo model) => model.toRow();

  @override
  Map<String, dynamic> definition() => {
        'fecha_ingreso': Fake.pastDate(),
        'descripcion': Fake.chance(60) ? Fake.sentence() : null,
        'estado': 1,
      };
}
