import '../seeders/seed_target.dart';

/// Base de las factories (estilo Laravel).
///
/// Cada factory solo define [definition]: cómo se ve una fila falsa,
/// con las mismas claves que la tabla. El resto viene gratis:
///
/// ```dart
/// final v  = VentaFactory().make();                       // en memoria
/// final v2 = VentaFactory().make({'cliente_id': 5});      // sobreescribe campos
/// final v3 = await VentaFactory().create(target);         // insertada, con id
/// final vs = await VentaFactory().createMany(target, 10);
/// ```
/// `target` es un [SeedTarget], p. ej. `MysqlTarget(connection)`.
abstract class Factory<T> {
  /// Tabla donde [create] inserta.
  String get table;

  /// Convierte una fila (Map) en el modelo.
  T fromRow(Map<String, dynamic> row);

  /// Convierte el modelo en una fila plana de la tabla.
  Map<String, dynamic> toRow(T model);

  /// Atributos falsos por defecto de un registro.
  Map<String, dynamic> definition();

  T make([Map<String, dynamic> attributes = const {}]) =>
      fromRow({...definition(), ...attributes});

  List<T> makeMany(int count, [Map<String, dynamic> attributes = const {}]) =>
      List.generate(count, (_) => make(attributes));

  /// Inserta el registro y lo devuelve con su `id` asignado.
  Future<T> create(SeedTarget target, [Map<String, dynamic> attributes = const {}]) async {
    final row = toRow(make(attributes))..removeWhere((k, v) => k == 'id' && v == null);
    final id = await target.insert(table, row);
    return fromRow({...row, 'id': id});
  }

  Future<List<T>> createMany(
    SeedTarget target,
    int count, [
    Map<String, dynamic> attributes = const {},
  ]) async {
    final result = <T>[];
    for (var i = 0; i < count; i++) {
      result.add(await create(target, attributes));
    }
    return result;
  }
}
