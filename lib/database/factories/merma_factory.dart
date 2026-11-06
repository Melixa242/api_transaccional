import '../../models/merma.dart';
import 'factory.dart';
import 'fake.dart';

/// Requiere `produccion_id` en los atributos al usar [create].
class MermaFactory extends Factory<Merma> {
  @override
  String get table => 'mermas';

  @override
  Merma fromRow(Map<String, dynamic> row) => Merma.fromJson(row);

  @override
  Map<String, dynamic> toRow(Merma model) => model.toRow();

  @override
  Map<String, dynamic> definition() => {
        'cantidad': Fake.decimal(0.5, 10),
        'estado': 1,
      };
}
