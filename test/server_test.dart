import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

/// Arranca `bin/server.dart` apuntando a un MySQL inexistente (puerto 1):
/// prueba autenticación, CORS y health sin tocar ninguna base real.
void main() {
  const port = '8099';
  const apiKey = 'clave-de-prueba';
  final host = 'http://127.0.0.1:$port';
  late Process p;

  setUpAll(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'PORT': port, 'API_KEY': apiKey, 'MYSQL_HOST': '127.0.0.1', 'MYSQL_PORT': '1'},
    );
    // Hay que vaciar stderr: si el buffer se llena, el servidor se bloquea al loguear.
    p.stderr.drain<void>();
    final arranco = Completer<void>();
    p.stdout.transform(utf8.decoder).listen((l) {
      if (!arranco.isCompleted && l.contains('Servidor')) arranco.complete();
    });
    await arranco.future;
  });

  tearDownAll(() => p.kill());

  test('la raíz muestra la documentación sin API key', () async {
    final r = await get(Uri.parse('$host/'));
    expect(r.statusCode, 200);
    expect(r.headers['content-type'], contains('text/html'));
    expect(r.body, contains('/api/ventas'));
  });

  test('/api devuelve la documentación en JSON sin API key', () async {
    final r = await get(Uri.parse('$host/api'));
    expect(r.statusCode, 200);
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    expect((body['recursos'] as Map).containsKey('Ventas'), isTrue);
  });

  test('sin API key responde 401', () async {
    final r = await get(Uri.parse('$host/api/ventas'));
    expect(r.statusCode, 401);
  });

  test('con API key incorrecta responde 401', () async {
    final r = await get(Uri.parse('$host/api/ventas'), headers: {'X-API-Key': 'otra'});
    expect(r.statusCode, 401);
  });

  test('ruta inexistente con API key responde 404', () async {
    final r = await get(Uri.parse('$host/api/no-existe'), headers: {'Authorization': 'Bearer $apiKey'});
    expect(r.statusCode, 404);
  });

  test('error de base de datos: 500 genérico, sin detalles internos', () async {
    final r = await get(Uri.parse('$host/api/ventas'), headers: {'X-API-Key': apiKey});
    expect(r.statusCode, 500);
    expect(jsonDecode(r.body), {'error': 'Error interno del servidor'});
  });

  test('health no exige API key y reporta la base caída', () async {
    final r = await get(Uri.parse('$host/api/health'));
    expect(r.statusCode, 503);
    expect(jsonDecode(r.body)['db'], 'error');
  });

  test('preflight OPTIONS incluye cabeceras CORS', () async {
    final req = Request('OPTIONS', Uri.parse('$host/api/ventas'));
    final r = await Response.fromStream(await Client().send(req));
    expect(r.statusCode, 200);
    expect(r.headers['access-control-allow-headers'], contains('X-API-Key'));
  });
}
