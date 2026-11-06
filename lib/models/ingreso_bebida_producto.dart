class IngresoBebidaProducto  {
  final int? id;
  final int? ingresoBebidaId;
  final int productoId;
  final String? productoNombre;
  final double cantidadIngresa;
  final double precio;
  final int estado;

  IngresoBebidaProducto({
    this.id,
    this.ingresoBebidaId,
    required this.productoId,
    this.productoNombre,
    required this.cantidadIngresa,
    this.precio = 0,
    this.estado = 1,
  });

  factory IngresoBebidaProducto.fromJson(Map<String, dynamic> j) => IngresoBebidaProducto(
        id: num.tryParse('${j['id']}')?.toInt(),
        ingresoBebidaId: num.tryParse('${j['ingreso_bebida_id']}')?.toInt(),
        productoId: num.tryParse('${j['producto_id']}')?.toInt() ?? 0,
        productoNombre: j['producto'] is Map ? j['producto']['nombre']?.toString() : null,
        cantidadIngresa: double.tryParse('${j['cantidad_ingresa']}') ?? 0,
        precio: double.tryParse('${j['precio']}') ?? 0,
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'ingreso_bebida_id': ingresoBebidaId,
        'producto_id': productoId,
        'cantidad_ingresa': cantidadIngresa,
        'precio': precio,
        'estado': estado,
      };
}
