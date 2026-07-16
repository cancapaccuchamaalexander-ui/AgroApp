import 'etapa_cultivo.dart';

class Cultivo {
  int? id;
  int parcelaId;
  String nombre;
  String variedad;
  String fechaSiembra;
  EtapaCultivo etapa;

  Cultivo({
    this.id,
    required this.parcelaId,
    required this.nombre,
    required this.variedad,
    required this.fechaSiembra,
    required this.etapa,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parcela_id': parcelaId,
      'nombre': nombre,
      'variedad': variedad,
      'fecha_siembra': fechaSiembra,
      'etapa': etapa.name, 
    };
  }

  factory Cultivo.fromMap(Map<String, dynamic> map) {
    return Cultivo(
      id: map['id'],
      parcelaId: map['parcela_id'],
      nombre: map['nombre'],
      variedad: map['variedad'],
      fechaSiembra: map['fecha_siembra'],
      etapa: EtapaCultivoExtension.desdeTexto(map['etapa']),
    );
  }
}