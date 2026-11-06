/// Dónde insertan las factories y los seeders.
///
/// Separa la lógica de sembrado del motor: la misma [Factory]/[Seeder] sirve
/// para cualquier motor (hoy MySQL, [MysqlTarget]).
/// Este archivo no importa ningún driver, así que se puede usar desde
/// `dart run` (sin Flutter).
abstract class SeedTarget {
  /// Inserta [row] en [table] y devuelve el id generado.
  Future<int> insert(String table, Map<String, dynamic> row);
}
