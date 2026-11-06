import '../../database/database.dart';
import 'package:mysql_client/mysql_client.dart';

/// Rechazo al ejecutar una orden; [status] es el código HTTP a devolver.
class EjecucionException implements Exception {
  final int status;
  final String message;
  const EjecucionException(this.status, this.message);
}

/// Acceso MySQL a `orden_producciones` y sus insumos (lado servidor / shelf).
class OrdenProduccionService {
  final DbPool connection;

  OrdenProduccionService(this.connection);

  static const _columnas = 'id, numero_orden, fecha_programada, regla_conversion_id, observaciones, estado';

  Future<List<Map<String, dynamic>>> obtenerTodos() async {
    final result = await connection.execute(
      'SELECT $_columnas FROM orden_producciones WHERE estado = 1 ORDER BY fecha_programada DESC, id DESC',
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> buscar(String query) async {
    final result = await connection.execute(
      'SELECT $_columnas FROM orden_producciones '
      'WHERE estado = 1 AND (numero_orden LIKE :q OR observaciones LIKE :q OR fecha_programada LIKE :q) '
      'ORDER BY fecha_programada DESC, id DESC',
      {'q': '%$query%'},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  Future<List<Map<String, dynamic>>> insumos(int ordenProduccionId) async {
    final result = await connection.execute(
      'SELECT id, insumo_id, cantidad FROM orden_produccion_insumo '
      'WHERE orden_produccion_id = :id AND estado = 1',
      {'id': ordenProduccionId},
    );
    return result.rows.map((row) => row.assoc()).toList();
  }

  /// Si algún insumo de la orden ya tiene producción, sus insumos no se pueden
  /// reemplazar ni borrar: `producciones` quedaría huérfana (FK con SET NULL).
  Future<bool> tieneProducciones(int ordenProduccionId) async {
    final result = await connection.execute(
      'SELECT 1 FROM producciones p JOIN orden_produccion_insumo oi ON oi.id = p.orden_produccion_insumo_id '
      'WHERE oi.orden_produccion_id = :id LIMIT 1',
      {'id': ordenProduccionId},
    );
    return result.numOfRows > 0;
  }

  /// Inserta cabecera + insumos en una transacción. Devuelve el id creado.
  /// Si no viene numero_orden se genera como en Laravel (OR-PRO-YYYY-MM-NNNN).
  Future<int> insertar(Map<String, dynamic> orden, List<Map<String, dynamic>> insumos) {
    return connection.transactional((conn) async {
      if (orden['numero_orden'] == null) orden = {...orden, 'numero_orden': await _generarNumeroOrden(conn)};
      final result = await conn.execute(
        'INSERT INTO orden_producciones (numero_orden, fecha_programada, regla_conversion_id, observaciones, estado, created_at, updated_at) '
        'VALUES (:numero_orden, :fecha_programada, :regla_conversion_id, :observaciones, 1, NOW(), NOW())',
        orden,
      );
      final id = result.lastInsertID.toInt();
      await _insertarInsumos(conn, id, insumos);
      return id;
    });
  }

  /// Actualiza la cabecera y reemplaza sus insumos. Devuelve 0 si no existe.
  Future<int> editar(int id, Map<String, dynamic> orden, List<Map<String, dynamic>> insumos) {
    return connection.transactional((conn) async {
      final existe = await conn.execute('SELECT 1 FROM orden_producciones WHERE id = :id', {'id': id});
      if (existe.numOfRows == 0) return 0;

      await conn.execute(
        'UPDATE orden_producciones SET numero_orden = COALESCE(:numero_orden, numero_orden), fecha_programada = :fecha_programada, '
        'regla_conversion_id = :regla_conversion_id, observaciones = :observaciones, updated_at = NOW() '
        'WHERE id = :id',
        {...orden, 'id': id},
      );
      await conn.execute('DELETE FROM orden_produccion_insumo WHERE orden_produccion_id = :id', {'id': id});
      await _insertarInsumos(conn, id, insumos);
      return 1;
    });
  }

  Future<IResultSet> eliminar(int id) =>
      connection.execute('DELETE FROM orden_producciones WHERE id = :id', {'id': id});

  /// Datos para ejecutar la orden: receta, producto resultante, insumos pendientes
  /// y el rango de cantidad obtenida que acepta la receta.
  Future<Map<String, dynamic>?> datosEjecucion(int ordenId) =>
      connection.withConnection((conn) => _datosEjecucion(conn, ordenId));

  /// Ejecuta el lote pendiente de la orden (misma lógica que Laravel
  /// `ProduccionApiController::loteStore`): crea una producción por insumo
  /// pendiente, descuenta `insumos.stock_actual` y suma la cantidad obtenida a
  /// `productos.cantidad_actual`, todo en una transacción.
  Future<Map<String, dynamic>> ejecutar(int ordenId, double cantidadObtenida) {
    return connection.transactional((conn) async {
      final datos = await _datosEjecucion(conn, ordenId);
      if (datos == null) throw const EjecucionException(404, 'Orden de producción no encontrada');
      final regla = datos['regla'] as Map<String, dynamic>?;
      final producto = datos['producto'] as Map<String, dynamic>?;
      final pendientes = datos['pendientes'] as List<Map<String, dynamic>>;
      if (regla == null) {
        throw const EjecucionException(422, 'Esta orden no tiene una receta (regla de conversión) asignada.');
      }
      if (producto == null) {
        throw const EjecucionException(422, 'No se pudo determinar el producto resultante de la receta asignada.');
      }
      if (pendientes.isEmpty) {
        throw const EjecucionException(422, 'Esta orden no tiene insumos pendientes de producción.');
      }
      final minimo = datos['minimo'] as double, maximo = datos['maximo'] as double;
      if (cantidadObtenida < minimo || cantidadObtenida > maximo) {
        throw EjecucionException(
            422,
            'La cantidad obtenida de ${cantidadObtenida.toStringAsFixed(2)} está fuera del rendimiento permitido '
            'para ${(datos['cantidad_planificada'] as double).toStringAsFixed(2)} planificados. '
            'Debe estar entre ${minimo.toStringAsFixed(2)} y ${maximo.toStringAsFixed(2)}.');
      }

      for (final d in pendientes) {
        final insumo = await conn.execute(
          'SELECT nombre, stock_actual FROM insumos WHERE id = :id FOR UPDATE',
          {'id': d['insumo_id']},
        );
        final fila = insumo.rows.first.assoc();
        final stock = double.parse(fila['stock_actual']!);
        final requerido = double.parse((d['cantidad'] as double).toStringAsFixed(2));
        if (stock < requerido) {
          throw EjecucionException(400,
              'Stock insuficiente para el insumo "${fila['nombre']}". Disponible: ${fila['stock_actual']}, requerido: $requerido.');
        }
        await conn.execute(
          'INSERT INTO producciones (orden_produccion_insumo_id, regla_conversion_id, producto_id, '
          'cantidad_insumo, cantidad_obtenida, nivel, estado, created_at, updated_at) '
          'VALUES (:oi, :regla, :producto, :cantidad_insumo, :cantidad_obtenida, 0, 1, NOW(), NOW())',
          {
            'oi': d['id'],
            'regla': regla['id'],
            'producto': producto['id'],
            'cantidad_insumo': requerido,
            'cantidad_obtenida': cantidadObtenida,
          },
        );
        await conn.execute(
          'UPDATE insumos SET stock_actual = stock_actual - :cantidad, updated_at = NOW() WHERE id = :id',
          {'cantidad': requerido, 'id': d['insumo_id']},
        );
      }
      await conn.execute(
        'UPDATE productos SET cantidad_actual = cantidad_actual + :cantidad, updated_at = NOW() WHERE id = :id',
        {'cantidad': cantidadObtenida.round(), 'id': producto['id']},
      );

      return {
        'mensaje': 'Producción ejecutada correctamente. Se descontaron ${pendientes.length} insumo(s) y se '
            'generaron ${cantidadObtenida.toStringAsFixed(2)} unidades de ${producto['nombre']}.',
        'producciones': pendientes.length,
      };
    });
  }

  Future<Map<String, dynamic>?> _datosEjecucion(MySQLConnection conn, int ordenId) async {
    final orden = await conn.execute(
      'SELECT $_columnas FROM orden_producciones WHERE id = :id',
      {'id': ordenId},
    );
    if (orden.numOfRows == 0) return null;
    final ordenRow = orden.rows.first.assoc();

    Map<String, dynamic>? regla;
    Map<String, dynamic>? producto;
    final reglaId = int.tryParse(ordenRow['regla_conversion_id'] ?? '');
    if (reglaId != null) {
      final r = await conn.execute(
        'SELECT id, nombre_insumo, producto_resultante, rendimiento_min, rendimiento_max '
        'FROM reglas_conversion WHERE id = :id',
        {'id': reglaId},
      );
      if (r.numOfRows > 0) regla = r.rows.first.assoc();
    }
    if (regla != null && (regla['producto_resultante'] ?? '').trim().isNotEmpty) {
      // Como `ReglaConversion::resolverProducto()`: se busca el producto por nombre.
      final p = await conn.execute(
        'SELECT id, nombre FROM productos WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(:nombre)) LIMIT 1',
        {'nombre': regla['producto_resultante']},
      );
      if (p.numOfRows > 0) producto = p.rows.first.assoc();
    }

    final p = await conn.execute(
      'SELECT oi.id, oi.insumo_id, oi.cantidad, i.nombre AS insumo FROM orden_produccion_insumo oi '
      'JOIN insumos i ON i.id = oi.insumo_id '
      'LEFT JOIN producciones pr ON pr.orden_produccion_insumo_id = oi.id '
      'WHERE oi.orden_produccion_id = :id AND oi.estado = 1 AND pr.id IS NULL ORDER BY oi.id',
      {'id': ordenId},
    );
    final pendientes = p.rows.map((row) {
      final m = row.assoc();
      return <String, dynamic>{
        'id': int.parse(m['id']!),
        'insumo_id': int.parse(m['insumo_id']!),
        'insumo': m['insumo'],
        'cantidad': double.parse(m['cantidad']!),
      };
    }).toList();

    // El rendimiento se calcula sobre el insumo principal de la receta (o el primero).
    final nombreInsumo = (regla?['nombre_insumo'] ?? '').trim().toLowerCase();
    final principal = pendientes.firstWhere(
      (d) => (d['insumo'] as String? ?? '').trim().toLowerCase() == nombreInsumo,
      orElse: () => pendientes.isEmpty ? <String, dynamic>{'cantidad': 0.0} : pendientes.first,
    );
    final planificada = principal['cantidad'] as double;
    final min = double.tryParse(regla?['rendimiento_min'] ?? '') ?? 0;
    final max = double.tryParse(regla?['rendimiento_max'] ?? '') ?? 0;

    return {
      'orden': ordenRow,
      'regla': regla,
      'producto': producto,
      'pendientes': pendientes,
      'cantidad_planificada': planificada,
      'minimo': planificada * min,
      'maximo': planificada * max,
      'ejecutable': regla != null && producto != null && pendientes.isNotEmpty,
    };
  }

  Future<String> _generarNumeroOrden(MySQLConnection conn) async {
    final ahora = DateTime.now();
    final prefijo = 'OR-PRO-${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-';
    final ultima = await conn.execute('SELECT numero_orden FROM orden_producciones ORDER BY id DESC LIMIT 1');
    var numero = 1;
    if (ultima.numOfRows > 0) {
      final m = RegExp(r'-(\d{4})$').firstMatch(ultima.rows.first.colAt(0) ?? '');
      if (m != null) numero = int.parse(m.group(1)!) + 1;
    }
    return '$prefijo${numero.toString().padLeft(4, '0')}';
  }

  Future<void> _insertarInsumos(MySQLConnection conn, int ordenId, List<Map<String, dynamic>> insumos) async {
    for (final i in insumos) {
      await conn.execute(
        'INSERT INTO orden_produccion_insumo (orden_produccion_id, insumo_id, cantidad, estado, created_at, updated_at) '
        'VALUES (:orden_produccion_id, :insumo_id, :cantidad, 1, NOW(), NOW())',
        {...i, 'orden_produccion_id': ordenId},
      );
    }
  }
}
