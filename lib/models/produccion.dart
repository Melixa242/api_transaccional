class Produccion {
  final int? id;
  final int? ordenProduccionInsumoId;
  final int? reglaConversionId;
  final int? productoId;
  final String? productoNombre;
  final double cantidadInsumo;
  final double cantidadObtenida;
  final int nivel;
  final int estado;

  Produccion({
    this.id,
    this.ordenProduccionInsumoId,
    this.reglaConversionId,
    this.productoId,
    this.productoNombre,
    this.cantidadInsumo = 0,
    this.cantidadObtenida = 0,
    this.nivel = 0,
    this.estado = 1,
  });

  factory Produccion.fromJson(Map<String, dynamic> j) => Produccion(
        id: num.tryParse('${j['id']}')?.toInt(),
        ordenProduccionInsumoId: num.tryParse('${j['orden_produccion_insumo_id']}')?.toInt(),
        reglaConversionId: num.tryParse('${j['regla_conversion_id']}')?.toInt(),
        productoId: num.tryParse('${j['producto_id']}')?.toInt(),
        productoNombre: j['producto'] is Map ? j['producto']['nombre']?.toString() : null,
        cantidadInsumo: double.tryParse('${j['cantidad_insumo']}') ?? 0,
        cantidadObtenida: double.tryParse('${j['cantidad_obtenida']}') ?? 0,
        nivel: num.tryParse('${j['nivel']}')?.toInt() ?? 0,
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orden_produccion_insumo_id': ordenProduccionInsumoId,
        'regla_conversion_id': reglaConversionId,
        'producto_id': productoId,
        'cantidad_insumo': cantidadInsumo,
        'cantidad_obtenida': cantidadObtenida,
        'nivel': nivel,
        'estado': estado,
      };

  /// Fila plana para SQLite local.
  Map<String, dynamic> toRow() => toJson();
}
