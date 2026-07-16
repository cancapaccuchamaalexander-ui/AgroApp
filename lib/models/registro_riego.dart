class RegistroRiego {
  int? id;
  int cultivoId;
  String fecha; // 'yyyy-MM-dd'
  double cantidadAgua; // litros
  int? notificacionId;

  RegistroRiego({
    this.id,
    required this.cultivoId,
    required this.fecha,
    required this.cantidadAgua,
    this.notificacionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cultivo_id': cultivoId,
      'fecha': fecha,
      'cantidad_agua': cantidadAgua,
      'notificacion_id': notificacionId,
    };
  }

  factory RegistroRiego.fromMap(Map<String, dynamic> map) {
    return RegistroRiego(
      id: map['id'],
      cultivoId: map['cultivo_id'],
      fecha: map['fecha'],
      cantidadAgua: map['cantidad_agua'],
      notificacionId: map['notificacion_id'],
    );
  }
}