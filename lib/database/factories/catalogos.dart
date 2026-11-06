/// IDs de catálogos que viven en la API (MySQL) y no en SQLite local.
///
/// Los valores por defecto sirven para la base SQLite local (sin FK a
/// catálogos). Al sembrar MySQL, `MysqlTarget.cargarCatalogos()` los
/// reemplaza por los IDs reales de la base.
class Catalogos {
  static List<int> clienteIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static List<int> productoIds = [1, 2, 3, 4, 5, 6, 7, 8];
  static List<int> bebidaIds = [20, 21, 22, 23, 24];
  static List<int> insumoIds = [1, 2, 3, 4, 5, 6];
  static List<int> reglaConversionIds = [1, 2, 3];

  static const metodosPago = ['Efectivo', 'QR', 'Tarjeta', 'Transferencia'];
}
