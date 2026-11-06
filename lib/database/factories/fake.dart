import 'dart:math';

/// Generador mínimo de datos falsos (sin dependencias externas).
///
/// Usa una semilla fija por defecto para que los seeders sean
/// reproducibles; llama a [Fake.reseed] para cambiarla.
class Fake {
  static Random _rnd = Random(27);

  static void reseed([int? seed]) => _rnd = seed == null ? Random() : Random(seed);

  static int between(int min, int max) => min + _rnd.nextInt(max - min + 1);

  /// Decimal redondeado a [decimals] cifras (como columnas decimal de MySQL).
  static double decimal(double min, double max, {int decimals = 2}) {
    final v = min + _rnd.nextDouble() * (max - min);
    return double.parse(v.toStringAsFixed(decimals));
  }

  static bool chance(int percent) => _rnd.nextInt(100) < percent;

  static T element<T>(List<T> items) => items[_rnd.nextInt(items.length)];

  /// [count] elementos distintos de [items].
  static List<T> elements<T>(List<T> items, int count) =>
      (List<T>.of(items)..shuffle(_rnd)).take(count).toList();

  /// Fecha (yyyy-MM-dd) dentro de los últimos [days] días.
  static String pastDate({int days = 90}) =>
      _fecha(DateTime.now().subtract(Duration(days: _rnd.nextInt(days + 1))));

  /// Fecha (yyyy-MM-dd) dentro de los próximos [days] días.
  static String futureDate({int days = 30}) =>
      _fecha(DateTime.now().add(Duration(days: _rnd.nextInt(days + 1))));

  static String _fecha(DateTime d) => d.toIso8601String().substring(0, 10);

  static String digits(int length) =>
      List.generate(length, (_) => _rnd.nextInt(10)).join();

  static String sentence({int minWords = 3, int maxWords = 8}) {
    final words = List.generate(between(minWords, maxWords), (_) => element(_words));
    final s = words.join(' ');
    return '${s[0].toUpperCase()}${s.substring(1)}.';
  }

  static const _words = [
    'pollo', 'entrega', 'cliente', 'pedido', 'turno', 'mañana', 'tarde',
    'proveedor', 'revisar', 'stock', 'cocina', 'freidora', 'urgente',
    'sucursal', 'pendiente', 'lote', 'control', 'calidad', 'almacén', 'caja',
  ];
}
