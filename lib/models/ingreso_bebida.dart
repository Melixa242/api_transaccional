import 'ingreso_bebida_producto.dart';

class IngresoBebida {
  final int? id;
  final String nombre;
  final String? descripcion;
  final DateTime fechaIngreso;
  final int estado;
  final List<IngresoBebidaProducto> productos;

  IngresoBebida({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.fechaIngreso,
    this.estado = 1,
    this.productos = const [],
  });

  factory IngresoBebida.fromJson(Map<String, dynamic> j) => IngresoBebida(
        id: num.tryParse('${j['id']}')?.toInt(),
        nombre: (j['nombre'] ?? '').toString(),
        descripcion: j['descripcion']?.toString(),
        fechaIngreso: DateTime.tryParse('${j['fecha_ingreso']}') ?? DateTime.now(),
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
        productos: ((j['productos'] ?? j['ingreso_bebida_producto']) as List? ?? const [])
            .whereType<Map>()
            .map((e) => IngresoBebidaProducto.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'fecha_ingreso': fechaIngreso.toIso8601String().substring(0, 10),
        'estado': estado,
      };

  Map<String, dynamic> toJson() => {
        ...toRow()..remove('id'),
        'productos': productos.map((e) => e.toJson()).toList(),
      };
}
