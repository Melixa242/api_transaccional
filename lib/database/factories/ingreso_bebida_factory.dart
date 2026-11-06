import '../../models/ingreso_bebida.dart';
import 'factory.dart';
import 'fake.dart';

class IngresoBebidaFactory extends Factory<IngresoBebida> {
  @override
  String get table => 'ingreso_bebidas';

  @override
  IngresoBebida fromRow(Map<String, dynamic> row) => IngresoBebida.fromJson(row);

  @override
  Map<String, dynamic> toRow(IngresoBebida model) => model.toRow();

  @override
  Map<String, dynamic> definition() => {
        'nombre': 'Ingreso bebidas ${Fake.digits(4)}',
        'descripcion': Fake.chance(50) ? Fake.sentence() : null,
        'fecha_ingreso': Fake.pastDate(),
        'estado': 1,
      };
}
