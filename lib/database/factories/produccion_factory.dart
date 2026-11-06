import '../../models/produccion.dart';
import 'catalogos.dart';
import 'factory.dart';
import 'fake.dart';

/// `orden_produccion_insumo_id` es UNIQUE: pásalo al usar [create].
class ProduccionFactory extends Factory<Produccion> {
  @override
  String get table => 'producciones';

  @override
  Produccion fromRow(Map<String, dynamic> row) => Produccion.fromJson(row);

  @override
  Map<String, dynamic> toRow(Produccion model) => model.toRow();

  @override
  Map<String, dynamic> definition() {
    final insumo = Fake.decimal(10, 100);
    return {
      'regla_conversion_id': Fake.element(Catalogos.reglaConversionIds),
      'producto_id': Fake.element(Catalogos.productoIds),
      'cantidad_insumo': insumo,
      // Rendimiento entre 70 % y 95 % del insumo.
      'cantidad_obtenida': double.parse((insumo * Fake.decimal(0.70, 0.95)).toStringAsFixed(2)),
      'nivel': Fake.between(0, 2),
      'estado': 1,
    };
  }
}
