class OrdenProduccionInsumo {
  final int? id;
  final int? ordenProduccionId;
  final int insumoId;
  final String? insumoNombre;
  final double cantidad;
  final int estado;

  OrdenProduccionInsumo({
    this.id,
    this.ordenProduccionId,
    required this.insumoId,
    this.insumoNombre,
    required this.cantidad,
    this.estado = 1,
  });

  factory OrdenProduccionInsumo.fromJson(Map<String, dynamic> j) => OrdenProduccionInsumo(
        id: num.tryParse('${j['id']}')?.toInt(),
        ordenProduccionId: num.tryParse('${j['orden_produccion_id']}')?.toInt(),
        insumoId: num.tryParse('${j['insumo_id']}')?.toInt() ?? 0,
        insumoNombre: j['insumo'] is Map ? j['insumo']['nombre']?.toString() : null,
        cantidad: double.tryParse('${j['cantidad']}') ?? 0,
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'orden_produccion_id': ordenProduccionId,
        'insumo_id': insumoId,
        'cantidad': cantidad,
        'estado': estado,
      };

  /// Fila plana para SQLite local.
  Map<String, dynamic> toRow() => toJson();
}
