import 'orden_produccion_insumo.dart';

class OrdenProduccion {
  final int? id;
  final String numeroOrden;
  final DateTime fechaProgramada;
  final int? reglaConversionId;
  final String? observaciones;
  final int estado;
  final List<OrdenProduccionInsumo> insumos;

  OrdenProduccion({
    this.id,
    required this.numeroOrden,
    required this.fechaProgramada,
    this.reglaConversionId,
    this.observaciones,
    this.estado = 1,
    this.insumos = const [],
  });

  factory OrdenProduccion.fromJson(Map<String, dynamic> j) => OrdenProduccion(
        id: num.tryParse('${j['id']}')?.toInt(),
        numeroOrden: (j['numero_orden'] ?? '').toString(),
        fechaProgramada: DateTime.tryParse('${j['fecha_programada']}') ?? DateTime.now(),
        reglaConversionId: num.tryParse('${j['regla_conversion_id']}')?.toInt(),
        observaciones: j['observaciones']?.toString(),
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
        insumos: ((j['insumos'] ?? j['orden_produccion_insumo']) as List? ?? const [])
            .whereType<Map>()
            .map((e) => OrdenProduccionInsumo.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'numero_orden': numeroOrden,
        'fecha_programada': fechaProgramada.toIso8601String().substring(0, 10),
        'regla_conversion_id': reglaConversionId,
        'observaciones': observaciones,
        'estado': estado,
      };

  Map<String, dynamic> toJson() => {
        ...toRow()..remove('id'),
        'insumos': insumos.map((e) => e.toJson()).toList(),
      };
}
