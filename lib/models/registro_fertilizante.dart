class RegistroFertilizante {
  int? id;
  int cultivoId;
  String fecha;
  String producto;
  double dosis;

  RegistroFertilizante({
    this.id,
    required this.cultivoId,
    required this.fecha,
    required this.producto,
    required this.dosis,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cultivo_id': cultivoId,
      'fecha': fecha,
      'producto': producto,
      'dosis': dosis,
    };
  }

  factory RegistroFertilizante.fromMap(Map<String, dynamic> map) {
    return RegistroFertilizante(
      id: map['id'],
      cultivoId: map['cultivo_id'],
      fecha: map['fecha'],
      producto: map['producto'],
      dosis: map['dosis'],
    );
  }
}