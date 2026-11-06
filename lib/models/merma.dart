class Merma {
  final int? id;
  final int produccionId;
  final double cantidad;
  final int estado;

  Merma({this.id, required this.produccionId, required this.cantidad, this.estado = 1});

  factory Merma.fromJson(Map<String, dynamic> j) => Merma(
        id: num.tryParse('${j['id']}')?.toInt(),
        produccionId: num.tryParse('${j['produccion_id']}')?.toInt() ?? 0,
        cantidad: double.tryParse('${j['cantidad']}') ?? 0,
        estado: num.tryParse('${j['estado']}')?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'produccion_id': produccionId,
        'cantidad': cantidad,
        'estado': estado,
      };

  /// Fila plana para SQLite local.
  Map<String, dynamic> toRow() => toJson();
}
