import '../../models/orden_produccion.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

class OrdenProduccionFactory extends Factory<OrdenProduccion> {
  @override
  String get table => 'orden_producciones';

  @override
  OrdenProduccion fromRow(Map<String, dynamic> row) => OrdenProduccion.fromJson(row);

  @override
  Map<String, dynamic> toRow(OrdenProduccion model) => model.toRow();

  @override
  Map<String, dynamic> definition() => {
        // numero_orden es UNIQUE: los seeders lo pasan secuencial.
        'numero_orden': 'OP-${Fake.digits(6)}',
        'fecha_programada': Fake.futureDate(),
        'regla_conversion_id': Fake.element(Catalogos.reglaConversionIds),
        'observaciones': Fake.chance(40) ? Fake.sentence() : null,
        'estado': 1,
      };
}
