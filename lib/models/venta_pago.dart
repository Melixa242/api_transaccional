class VentaPago {
  final int? id;
  final int? ventaId;
  final String metodoPago;
  final double monto;
  final String? referencia;
  final int estado;

  VentaPago({
    this.id,
    this.ventaId,
    required this.metodoPago,
    required this.monto,
    this.referencia,
    this.estado = 1,
  });

  factory VentaPago.fromJson(Map<String, dynamic> j) => VentaPago(
        id: num.tryParse('${j['id']}')?.toInt(),
        ventaId: num.tryParse('${j['venta_id']}')?.toInt(),
        metodoPago: (j['metodo_pago'] ?? '').toString(),
        monto: double.tryParse('${j['monto']}') ?? 0,
        referencia: j['referencia']?.toString(),
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'venta_id': ventaId,
        'metodo_pago': metodoPago,
        'monto': monto,
        'referencia': referencia,
        'estado': estado,
      };

  /// Fila plana para SQLite local.
  Map<String, dynamic> toRow() => toJson();
}
