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
    RutaDoc('GET', '/api', 'Esta documentación: página web en el navegador, JSON para la app. También en /.'),
    RutaDoc('GET', '/docs', 'Esta documentación como página HTML para el navegador.'),
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

/// `GET /` y `GET /api` sin `Accept: text/html`: el catálogo en JSON (lo consume la app Flutter).
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

/// `GET /docs`, y `GET /` o `GET /api` desde un navegador: el catálogo como página HTML.
Response docsHtml(String version, {required bool requiereApiKey}) {
  final esc = const HtmlEscape(HtmlEscapeMode.attribute);
  final total = catalogoRutas.values.fold<int>(0, (s, l) => s + l.length);
  final grupos = StringBuffer();
  final indice = StringBuffer();
  var n = 0;
  for (final e in catalogoRutas.entries) {
    final id = 'g${n++}';
    indice.write('<a href="#$id">${esc.convert(e.key)}<span>${e.value.length}</span></a>');
    grupos.write('<section class="grupo" id="$id"><h2>${esc.convert(e.key)}</h2>');
    for (final r in e.value) {
      final ruta = esc.convert(r.ruta).replaceAll('&lt;id&gt;', '<i>&lt;id&gt;</i>');
      grupos.write('<div class="ruta" data-buscar="${esc.convert('${r.metodo} ${r.ruta} ${r.descripcion} ${e.key}'.toLowerCase())}">'
          '<span class="m m-${r.metodo.toLowerCase()}">${r.metodo}</span>'
          '<div class="info"><code>$ruta</code><p>${esc.convert(r.descripcion)}</p>'
          '${r.campos == null ? '' : '<p class="campos"><b>Body JSON:</b> ${esc.convert(r.campos!)}</p>'}'
          '</div><button class="copiar" data-ruta="${esc.convert(r.ruta)}" title="Copiar ruta">Copiar</button></div>');
    }
    grupos.write('</section>');
  }
  final auth = requiereApiKey
      ? 'Todas las rutas excepto <code>/</code>, <code>/api</code>, <code>/docs</code> y <code>/api/health</code> '
          'exigen el header <code>X-API-Key: &lt;clave&gt;</code> o <code>Authorization: Bearer &lt;clave&gt;</code>.'
      : 'Este servidor corre <b>sin autenticación</b> (API_KEY no definida).';

  final html = '''<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>API Pollos Krosty</title>
<style>
:root{--bg:#f7f7f5;--card:#fff;--tx:#1d1d1b;--mut:#6b6b66;--bd:#e4e3df;--acc:#c2410c;
--get:#15803d;--post:#1d4ed8;--put:#a16207;--delete:#b91c1c}
@media (prefers-color-scheme:dark){:root{--bg:#141413;--card:#1e1e1c;--tx:#ecebe7;--mut:#9c9b95;--bd:#33322f;--acc:#fb923c;
--get:#4ade80;--post:#60a5fa;--put:#facc15;--delete:#f87171}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--tx);font:15px/1.5 system-ui,-apple-system,Segoe UI,sans-serif}
header{padding:32px 16px 20px;max-width:1100px;margin:auto}
h1{margin:0;font-size:26px}h1 small{font-size:13px;color:var(--mut);font-weight:500;margin-left:8px}
.auth{margin:12px 0 0;color:var(--mut);max-width:760px}
code{font:13px/1.4 ui-monospace,Consolas,monospace}
.wrap{max-width:1100px;margin:auto;padding:0 16px 48px;display:grid;grid-template-columns:240px 1fr;gap:24px}
nav{position:sticky;top:16px;align-self:start;display:flex;flex-direction:column;gap:2px}
nav a{display:flex;justify-content:space-between;color:var(--tx);text-decoration:none;padding:6px 10px;border-radius:6px;font-size:14px}
nav a:hover{background:var(--card)}nav a span{color:var(--mut);font-size:12px}
#buscar{width:100%;padding:10px 12px;border:1px solid var(--bd);border-radius:8px;background:var(--card);color:var(--tx);font:inherit;margin-bottom:16px}
.grupo{margin-bottom:24px}.grupo h2{font-size:15px;margin:0 0 8px;color:var(--mut);text-transform:uppercase;letter-spacing:.04em}
.ruta{display:flex;gap:12px;align-items:flex-start;background:var(--card);border:1px solid var(--bd);border-radius:8px;padding:12px;margin-bottom:6px}
.m{flex:none;width:64px;text-align:center;font:700 12px/22px ui-monospace,Consolas,monospace;border-radius:4px;border:1px solid currentColor}
.m-get{color:var(--get)}.m-post{color:var(--post)}.m-put{color:var(--put)}.m-delete{color:var(--delete)}
.info{flex:1;min-width:0}.info code{font-weight:600;word-break:break-all}.info code i{color:var(--acc);font-style:normal}
.info p{margin:2px 0 0;color:var(--mut);font-size:14px}.campos{font-size:13px!important}
.copiar{flex:none;background:none;border:1px solid var(--bd);color:var(--mut);border-radius:6px;padding:4px 10px;cursor:pointer;font:inherit;font-size:12px}
.copiar:hover{color:var(--tx)}.oculto{display:none}
@media (max-width:760px){.wrap{grid-template-columns:1fr}nav{display:none}.ruta{flex-wrap:wrap}.copiar{display:none}}
</style></head><body>
<header><h1>API Pollos Krosty<small>v${esc.convert(version)} · $total rutas</small></h1>
<p class="auth">$auth También disponible en JSON (<code>Accept: application/json</code>).</p></header>
<div class="wrap"><nav>$indice</nav><main>
<input id="buscar" type="search" placeholder="Filtrar por ruta, método o descripción…" autocomplete="off">
$grupos</main></div>
<script>
const q=document.getElementById('buscar');
q.addEventListener('input',()=>{const t=q.value.trim().toLowerCase();
document.querySelectorAll('.ruta').forEach(r=>r.classList.toggle('oculto',!!t&&!r.dataset.buscar.includes(t)));
document.querySelectorAll('.grupo').forEach(g=>g.classList.toggle('oculto',!g.querySelector('.ruta:not(.oculto)')));});
document.querySelectorAll('.copiar').forEach(b=>b.addEventListener('click',()=>{
navigator.clipboard.writeText(location.origin+b.dataset.ruta).then(()=>{b.textContent='¡Copiado!';setTimeout(()=>b.textContent='Copiar',1200);});}));
</script></body></html>''';
  return Response.ok(html, headers: {'Content-Type': 'text/html; charset=utf-8'});
}
