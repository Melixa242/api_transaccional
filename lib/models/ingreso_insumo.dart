import 'ingreso_insumo_detalle.dart';

class IngresoInsumo {
  final int? id;
  final DateTime fechaIngreso;
  final String? descripcion;
  final int estado;
  final List<IngresoInsumoDetalle> detalles;

  IngresoInsumo({
    this.id,
    required this.fechaIngreso,
    this.descripcion,
    this.estado = 1,
    this.detalles = const [],
  });

  double get total => detalles.fold(0, (s, d) => s + d.cantidad * d.precioUnitario);

  factory IngresoInsumo.fromJson(Map<String, dynamic> j) => IngresoInsumo(
        id: num.tryParse('${j['id']}')?.toInt(),
        fechaIngreso: DateTime.tryParse('${j['fecha_ingreso']}') ?? DateTime.now(),
        descripcion: j['descripcion']?.toString(),
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
        detalles: ((j['detalles'] ?? j['ingreso_insumo_detalle']) as List? ?? const [])
            .whereType<Map>()
            .map((e) => IngresoInsumoDetalle.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'fecha_ingreso': fechaIngreso.toIso8601String().substring(0, 10),
        'descripcion': descripcion,
        'estado': estado,
      };

  Map<String, dynamic> toJson() => {
        ...toRow()..remove('id'),
        'detalles': detalles.map((e) => e.toJson()).toList(),
      };
}
