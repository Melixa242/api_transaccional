import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Una ruta documentada de la API.
class RutaDoc {
  const RutaDoc(this.metodo, this.ruta, this.descripcion, {this.campos});

  final String metodo;
  final String ruta;
  final String descripcion;

  /// Campos obligatorios del body JSON (POST/PUT).
  final String? campos;

  Map<String, Object?> toJson() => {
        'metodo': metodo,
        'ruta': ruta,
        'descripcion': descripcion,
        if (campos != null) 'campos': campos,
      };
}

/// Catálogo de rutas agrupado por recurso. Si se agrega una ruta en
/// `lib/rutas/`, hay que sumarla aquí para que aparezca en la documentación.
const catalogoRutas = <String, List<RutaDoc>>{
  'Sistema': [
    RutaDoc('GET', '/api', 'Esta documentación en JSON. También en /.'),
    RutaDoc('GET', '/api/health', 'Estado del servidor y de la base de datos. No exige API key.'),
  ],
  'Ventas': [
    RutaDoc('GET', '/api/ventas', 'Lista las ventas. Filtro opcional: ?q=texto.'),
    RutaDoc('GET', '/api/ventas/<id>/detalles', 'Detalles y pagos de una venta.'),
    RutaDoc('POST', '/api/ventas', 'Crea una venta con sus detalles y pagos.',
        campos: 'cliente_id, fecha_venta, total, detalles[] (producto_id, precio_unitario, cantidad), '
            'pagos[] (metodo_pago, monto). Opcionales: descuento, opcion_pago, observaciones.'),
    RutaDoc('PUT', '/api/ventas/<id>', 'Actualiza una venta.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/ventas/<id>', 'Elimina una venta.'),
  ],
  'Detalles de venta': [
    RutaDoc('GET', '/api/detalle-ventas', 'Lista los detalles de venta.'),
    RutaDoc('POST', '/api/detalle-ventas', 'Crea un detalle de venta.',
        campos: 'venta_id, producto_id, precio_unitario, cantidad'),
    RutaDoc('PUT', '/api/detalle-ventas/<id>', 'Actualiza un detalle de venta.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/detalle-ventas/<id>', 'Elimina un detalle de venta.'),
  ],
  'Pagos de venta': [
    RutaDoc('GET', '/api/venta-pagos', 'Lista los pagos.'),
    RutaDoc('POST', '/api/venta-pagos', 'Registra un pago.', campos: 'venta_id, metodo_pago (máx. 20 caracteres), monto'),
    RutaDoc('PUT', '/api/venta-pagos/<id>', 'Actualiza un pago.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/venta-pagos/<id>', 'Elimina un pago.'),
  ],
  'Ingresos de insumos': [
    RutaDoc('GET', '/api/ingreso-insumos', 'Lista los ingresos de insumos.'),
    RutaDoc('GET', '/api/ingreso-insumos/<id>/detalles', 'Detalles de un ingreso de insumos.'),
    RutaDoc('POST', '/api/ingreso-insumos', 'Crea un ingreso de insumos.'),
    RutaDoc('PUT', '/api/ingreso-insumos/<id>', 'Actualiza un ingreso de insumos.'),
    RutaDoc('DELETE', '/api/ingreso-insumos/<id>', 'Elimina un ingreso de insumos.'),
  ],
  'Detalles de ingreso de insumos': [
    RutaDoc('GET', '/api/ingreso-insumo-detalles', 'Lista los detalles. Alias: /api/ingreso-insumo-detalle.'),
    RutaDoc('POST', '/api/ingreso-insumo-detalles', 'Crea un detalle.',
        campos: 'ingreso_insumo_id, insumo_id, cantidad, precio_unitario'),
    RutaDoc('PUT', '/api/ingreso-insumo-detalles/<id>', 'Actualiza un detalle.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/ingreso-insumo-detalles/<id>', 'Elimina un detalle.'),
  ],
  'Ingresos de bebidas': [
    RutaDoc('GET', '/api/ingreso-bebidas', 'Lista los ingresos de bebidas.'),
    RutaDoc('GET', '/api/ingreso-bebidas/<id>/productos', 'Productos de un ingreso de bebidas.'),
    RutaDoc('POST', '/api/ingreso-bebidas', 'Crea un ingreso de bebidas.',
        campos: 'nombre, fecha_ingreso, productos[] (producto_id, cantidad_ingresa, precio)'),
    RutaDoc('PUT', '/api/ingreso-bebidas/<id>', 'Actualiza un ingreso de bebidas.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/ingreso-bebidas/<id>', 'Elimina un ingreso de bebidas.'),
  ],
  'Productos de ingreso de bebidas': [
    RutaDoc('GET', '/api/ingreso-bebida-productos', 'Lista los productos. Alias: /api/ingreso-bebida-producto.'),
    RutaDoc('POST', '/api/ingreso-bebida-productos', 'Crea un producto de ingreso.',
        campos: 'ingreso_bebida_id, producto_id, cantidad_ingresa'),
    RutaDoc('PUT', '/api/ingreso-bebida-productos/<id>', 'Actualiza un producto de ingreso.',
        campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/ingreso-bebida-productos/<id>', 'Elimina un producto de ingreso.'),
  ],
  'Órdenes de producción': [
    RutaDoc('GET', '/api/orden-producciones', 'Lista las órdenes. Alias: /api/ordenes.'),
    RutaDoc('GET', '/api/orden-producciones/<id>/insumos', 'Insumos de una orden.'),
    RutaDoc('GET', '/api/orden-producciones/<id>/ejecucion', 'Datos para ejecutar una orden.'),
    RutaDoc('POST', '/api/orden-producciones/<id>/ejecutar', 'Ejecuta una orden de producción.',
        campos: 'cantidad_obtenida (>= 0.01)'),
    RutaDoc('POST', '/api/orden-producciones', 'Crea una orden.',
        campos: 'fecha_programada, insumos[] (insumo_id, cantidad)'),
    RutaDoc('PUT', '/api/orden-producciones/<id>', 'Actualiza una orden.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/orden-producciones/<id>', 'Elimina una orden.'),
  ],
  'Insumos de orden de producción': [
    RutaDoc('GET', '/api/orden-produccion-insumos', 'Lista los insumos de órdenes.'),
    RutaDoc('POST', '/api/orden-produccion-insumos', 'Agrega un insumo a una orden.',
        campos: 'orden_produccion_id, insumo_id, cantidad'),
    RutaDoc('PUT', '/api/orden-produccion-insumos/<id>', 'Actualiza un insumo de orden.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/orden-produccion-insumos/<id>', 'Elimina un insumo de orden.'),
  ],
  'Producciones': [
    RutaDoc('GET', '/api/producciones', 'Lista las producciones. Alias: /api/produccion.'),
    RutaDoc('POST', '/api/producciones', 'Registra una producción.',
        campos: 'cantidad_insumo, cantidad_obtenida (>= 0)'),
    RutaDoc('PUT', '/api/producciones/<id>', 'Actualiza una producción.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/producciones/<id>', 'Elimina una producción.'),
  ],
  'Mermas': [
    RutaDoc('GET', '/api/mermas', 'Lista las mermas.'),
    RutaDoc('POST', '/api/mermas', 'Registra una merma.', campos: 'produccion_id, cantidad'),
    RutaDoc('PUT', '/api/mermas/<id>', 'Actualiza una merma.', campos: 'Los mismos que POST.'),
    RutaDoc('DELETE', '/api/mermas/<id>', 'Elimina una merma.'),
  ],
};

/// `GET /` y `GET /api`: el catálogo en JSON (lo consume la app Flutter).
Response docsJson(String version, {required bool requiereApiKey}) => Response.ok(
      jsonEncode({
        'nombre': 'API transaccional Pollos Krosty',
        'version': version,
        'autenticacion': requiereApiKey ? 'Header X-API-Key o Authorization: Bearer <clave>' : 'ninguna',
        'recursos': {
          for (final e in catalogoRutas.entries) e.key: [for (final r in e.value) r.toJson()],
        },
      }),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
