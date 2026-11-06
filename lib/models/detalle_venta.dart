class DetalleVenta  {
  final int? id;
  final int? ventaId;
  final int productoId;
  final String? productoNombre;
  final double precioUnitario;
  final double cantidad;
  final double subTotal;
  final int estado;

  DetalleVenta({
    this.id,
    this.ventaId,
    required this.productoId,
    this.productoNombre,
    required this.precioUnitario,
    required this.cantidad,
    double? subTotal,
    this.estado = 1,
  }) : subTotal = subTotal ?? precioUnitario * cantidad;

  factory DetalleVenta.fromJson(Map<String, dynamic> j) => DetalleVenta(
        id: num.tryParse('${j['id']}')?.toInt(),
        ventaId: num.tryParse('${j['venta_id']}')?.toInt(),
        productoId: num.tryParse('${j['producto_id']}')?.toInt() ?? 0,
        productoNombre: j['producto'] is Map ? j['producto']['nombre']?.toString() : null,
        precioUnitario: double.tryParse('${j['precio_unitario']}') ?? 0,
        cantidad: double.tryParse('${j['cantidad']}') ?? 0,
        subTotal: double.tryParse('${j['sub_total']}') ?? 0,
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'venta_id': ventaId,
        'producto_id': productoId,
        'precio_unitario': precioUnitario,
        'cantidad': cantidad,
        'sub_total': subTotal,
        'estado': estado,
      };
}
