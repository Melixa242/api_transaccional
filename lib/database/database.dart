import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

/// `K_SERVICE` lo define Cloud Run en cada contenedor.
bool get enProduccion => Platform.environment.containsKey('K_SERVICE');

class Database {
  static const _variablesObligatorias = ['MYSQL_HOST', 'MYSQL_USER', 'MYSQL_PASSWORD', 'MYSQL_DATABASE'];

  /// Una conexión suelta, para scripts (`bin/migrate.dart`, `bin/seed.dart`).
  /// El servidor usa [DbPool].
  static Future<MySQLConnection> connect() async {
    final env = Platform.environment;
    if (enProduccion) {
      final faltantes = _variablesObligatorias.where((v) => (env[v] ?? '').isEmpty).toList();
      if (faltantes.isNotEmpty) {
        throw StateError('Faltan variables de entorno: ${faltantes.join(', ')}');
      }
    }
    final connection = await MySQLConnection.createConnection(
      host: env['MYSQL_HOST'] ?? '127.0.0.1',
      port: int.tryParse(env['MYSQL_PORT'] ?? '') ?? 3306,
      userName: env['MYSQL_USER'] ?? 'root',
      password: env['MYSQL_PASSWORD'] ?? '',
      databaseName: env['MYSQL_DATABASE'] ?? 'iproduccion_pollos_krosty_sado',
    );
    await connection.connect();
    return connection;
  }
}

/// Pool de conexiones para el servidor.
///
/// Cada petición toma su propia conexión, así dos transacciones simultáneas no
/// se mezclan. Las conexiones que MySQL cerró (p. ej. por `wait_timeout`) se
/// descartan y se abren de nuevo al pedirlas.
class DbPool {
  DbPool({this.maxConnections = 5});

  final int maxConnections;
  final _idle = <MySQLConnection>[];
  final _waiters = Queue<Completer<MySQLConnection>>();
  int _total = 0;

  Future<IResultSet> execute(String query, [Map<String, dynamic>? params]) =>
      withConnection((conn) => conn.execute(query, params));

  Future<T> transactional<T>(FutureOr<T> Function(MySQLConnection conn) callback) =>
      withConnection((conn) => conn.transactional(callback));

  /// Presta una conexión del pool a [callback] y la devuelve al terminar.
  Future<T> withConnection<T>(Future<T> Function(MySQLConnection conn) callback) async {
    final conn = await _acquire();
    try {
      return await callback(conn);
    } finally {
      _release(conn);
    }
  }

  Future<MySQLConnection> _acquire() async {
    while (_idle.isNotEmpty) {
      final conn = _idle.removeLast();
      if (conn.connected) return conn;
      _total--;
    }
    if (_total < maxConnections) {
      _total++;
      try {
        return await Database.connect();
      } catch (_) {
        _total--;
        rethrow;
      }
    }
    final waiter = Completer<MySQLConnection>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void _release(MySQLConnection conn) {
    if (!conn.connected) {
      _total--;
      if (_waiters.isNotEmpty) {
        final waiter = _waiters.removeFirst();
        _acquire().then(waiter.complete, onError: waiter.completeError);
      }
      return;
    }
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete(conn);
    } else {
      _idle.add(conn);
    }
  }

  Future<void> close() async {
    for (final conn in _idle) {
      await conn.close();
    }
    _idle.clear();
  }
}
