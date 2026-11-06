class IngresoInsumoDetalle {
  final int? id;
  final int? ingresoInsumoId;
  final int insumoId;
  final String? insumoNombre;
  final double cantidad;
  final double precioUnitario;
  final int estado;

  IngresoInsumoDetalle({
    this.id,
    this.ingresoInsumoId,
    required this.insumoId,
    this.insumoNombre,
    required this.cantidad,
    required this.precioUnitario,
    this.estado = 1,
  });

  factory IngresoInsumoDetalle.fromJson(Map<String, dynamic> j) => IngresoInsumoDetalle(
        id: num.tryParse('${j['id']}')?.toInt(),
        ingresoInsumoId: num.tryParse('${j['ingreso_insumo_id']}')?.toInt(),
        insumoId: num.tryParse('${j['insumo_id']}')?.toInt() ?? 0,
        insumoNombre: j['insumo'] is Map ? j['insumo']['nombre']?.toString() : null,
        cantidad: double.tryParse('${j['cantidad']}') ?? 0,
        precioUnitario: double.tryParse('${j['precio_unitario']}') ?? 0,
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingreso_insumo_id': ingresoInsumoId,
        'insumo_id': insumoId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'estado': estado,
      };

  /// Fila plana para SQLite local.
  Map<String, dynamic> toRow() => toJson();
}
