class Parcela {
  int? id;
  String nombre;
  String ubicacion;
  double areaHectareas;
  String? fotoPath;   // 👈 nuevo: ruta de la foto guardada
  double? latitud;    // 👈 nuevo
  double? longitud;   // 👈 nuevo

  Parcela({
    this.id,
    required this.nombre,
    required this.ubicacion,
    required this.areaHectareas,
    this.fotoPath,
    this.latitud,
    this.longitud,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'area_hectareas': areaHectareas,
      'foto_path': fotoPath,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  factory Parcela.fromMap(Map<String, dynamic> map) {
    return Parcela(
      id: map['id'],
      nombre: map['nombre'],
      ubicacion: map['ubicacion'],
      areaHectareas: map['area_hectareas'],
      fotoPath: map['foto_path'],
      latitud: map['latitud'],
      longitud: map['longitud'],
    );
  }
}