import 'detalle_venta.dart';
import 'venta_pago.dart';

class Venta {
  final int? id;
  final int clienteId;
  final String? clienteNombre; // viene si la API hace with('cliente')
  final DateTime fechaVenta;
  final String? observaciones;
  final String opcionPago;
  final double descuento;
  final double total;
  final int estado;
  final List<DetalleVenta> detalles;
  final List<VentaPago> pagos;

  Venta({
    this.id,
    required this.clienteId,
    this.clienteNombre,
    required this.fechaVenta,
    this.observaciones,
    this.opcionPago = 'Efectivo',
    this.descuento = 0,
    this.total = 0,
    this.estado = 1,
    this.detalles = const [],
    this.pagos = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> j) => Venta(
        id: num.tryParse('${j['id']}')?.toInt(),
        clienteId: num.tryParse('${j['cliente_id']}')?.toInt() ?? 0,
        clienteNombre: j['cliente'] is Map ? j['cliente']['nombre']?.toString() : null,
        fechaVenta: DateTime.tryParse('${j['fecha_venta']}') ?? DateTime.now(),
        observaciones: j['observaciones']?.toString(),
        opcionPago: (j['opcion_pago'] ?? 'Efectivo').toString(),
        descuento: double.tryParse('${j['descuento']}') ?? 0,
        total: double.tryParse('${j['total']}') ?? 0,
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
        detalles: ((j['detalles'] ?? j['detalle_ventas']) as List? ?? const []).whereType<Map>().map((e) => DetalleVenta.fromJson(Map<String, dynamic>.from(e))).toList(),
        pagos: ((j['pagos'] ?? j['venta_pagos']) as List? ?? const []).whereType<Map>().map((e) => VentaPago.fromJson(Map<String, dynamic>.from(e))).toList(),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'cliente_id': clienteId,
        'fecha_venta': fechaVenta.toIso8601String().substring(0, 10),
        'observaciones': observaciones,
        'opcion_pago': opcionPago,
        'descuento': descuento,
        'total': total,
        'estado': estado,
      };

  Map<String, dynamic> toJson() => {
        ...toRow()..remove('id'),
        'detalles': detalles.map((e) => e.toJson()).toList(),
        'pagos': pagos.map((e) => e.toJson()).toList(),
      };
}
