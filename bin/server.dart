import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:proyecto_krosty/database/database.dart';
import 'package:proyecto_krosty/rutas/detalle_venta_route.dart';
import 'package:proyecto_krosty/rutas/docs_route.dart';
import 'package:proyecto_krosty/rutas/ingreso_bebida_producto_route.dart';
import 'package:proyecto_krosty/rutas/ingreso_bebida_route.dart';
import 'package:proyecto_krosty/rutas/ingreso_insumo_detalle_route.dart';
import 'package:proyecto_krosty/rutas/ingreso_insumo_route.dart';
import 'package:proyecto_krosty/rutas/merma_route.dart';
import 'package:proyecto_krosty/rutas/orden_produccion_insumo_route.dart';
import 'package:proyecto_krosty/rutas/orden_produccion_route.dart';
import 'package:proyecto_krosty/rutas/produccion_route.dart';
import 'package:proyecto_krosty/rutas/venta_pago_route.dart';
import 'package:proyecto_krosty/rutas/venta_route.dart';

const version = '1.0.0';

void main() async {
  final env = Platform.environment;
  final apiKey = env['API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    print('⚠️  API_KEY no definida: la API corre SIN autenticación; cualquiera puede leer y escribir datos.');
  }

  final connection = DbPool(maxConnections: int.tryParse(env['DB_POOL_SIZE'] ?? '') ?? 5);

  final router = Router();
  // Documentación pública: un navegador (Accept: text/html) ve la página web;
  // la app Flutter y otros clientes (Accept: application/json) reciben el JSON.
  final conKey = apiKey.isNotEmpty;
  Response docs(Request request) => (request.headers['accept'] ?? '').contains('text/html')
      ? docsHtml(version, requiereApiKey: conKey)
      : docsJson(version, requiereApiKey: conKey);
  router.get('/', docs);
  router.get('/api', docs);
  router.get('/docs', (Request request) => docsHtml(version, requiereApiKey: conKey));
  router.get('/api/health', (Request request) async {
    try {
      await connection.execute('SELECT 1');
      return _json(200, {'status': 'ok', 'version': version, 'db': 'ok'});
    } catch (e) {
      stderr.writeln('Health check: sin base de datos: $e');
      return _json(503, {'status': 'error', 'version': version, 'db': 'error'});
    }
  });
  router.mount('/', ventaRoutes(connection).call);
  router.mount('/', detalleVentaRoutes(connection).call);
  router.mount('/', ventaPagoRoutes(connection).call);
  router.mount('/', ingresoInsumoRoutes(connection).call);
  router.mount('/', ingresoInsumoDetalleRoutes(connection).call);
  router.mount('/', ingresoBebidaRoutes(connection).call);
  router.mount('/', ingresoBebidaProductoRoutes(connection).call);
  router.mount('/', ordenProduccionRoutes(connection).call);
  router.mount('/', ordenProduccionInsumoRoutes(connection).call);
  router.mount('/', produccionRoutes(connection).call);
  router.mount('/', mermaRoutes(connection).call);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(env['CORS_ORIGIN'] ?? '*'))
      .addMiddleware(manejarErrores())
      .addMiddleware(apiKeyAuth(apiKey))
      .addHandler(router.call);

  // Cloud Run indica el puerto en PORT; 8081 es el de desarrollo local.
  final port = int.tryParse(env['PORT'] ?? '') ?? 8081;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Servidor $version corriendo en http://${server.address.host}:${server.port}');

  // Cloud Run manda SIGTERM antes de apagar la instancia.
  Future<void> apagar(ProcessSignal signal) async {
    print('Recibido $signal, cerrando...');
    await server.close();
    await connection.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(apagar);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(apagar);
}

Response _json(int status, Object body) =>
    Response(status, body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

/// Exige `X-API-Key: <API_KEY>` (o `Authorization: Bearer <API_KEY>`) en todo
/// menos `/api/health` y la documentación (`/`, `/api`, `/docs`). Con [apiKey] vacía no valida nada (desarrollo).
const _rutasPublicas = {'', 'api', 'docs', 'api/health'};

Middleware apiKeyAuth(String apiKey) {
  return (Handler inner) => (Request request) {
        if (apiKey.isEmpty || _rutasPublicas.contains(request.url.path)) return inner(request);
        final auth = request.headers['authorization'] ?? '';
        final recibida = request.headers['x-api-key'] ?? (auth.startsWith('Bearer ') ? auth.substring(7) : '');
        if (!_igualesTiempoConstante(recibida, apiKey)) {
          return _json(401, {'error': 'No autorizado'});
        }
        return inner(request);
      };
}

bool _igualesTiempoConstante(String a, String b) {
  final x = utf8.encode(a), y = utf8.encode(b);
  var diff = x.length ^ y.length;
  for (var i = 0; i < x.length && i < y.length; i++) {
    diff |= x[i] ^ y[i];
  }
  return diff == 0;
}

/// Un error no previsto se registra en el log y el cliente solo ve un 500 genérico.
Middleware manejarErrores() {
  return (Handler inner) => (Request request) async {
        try {
          return await inner(request);
        } on HijackException {
          rethrow;
        } catch (e, st) {
          stderr.writeln('ERROR ${request.method} /${request.url}: $e\n$st');
          return _json(500, {'error': 'Error interno del servidor'});
        }
      };
}

/// Permite llamadas desde la app (web/emulador) y responde los preflight OPTIONS.
Middleware corsHeaders(String origin) {
  final headers = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-API-Key',
  };
  return (Handler inner) => (Request request) async {
        if (request.method == 'OPTIONS') return Response.ok('', headers: headers);
        final response = await inner(request);
        return response.change(headers: headers);
      };
}
