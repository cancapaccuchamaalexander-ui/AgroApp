enum EtapaCultivo {
  semilla,
  germinacion,
  crecimiento,
  floracion,
  cosecha,
}

extension EtapaCultivoExtension on EtapaCultivo {
  String get etiqueta {
    switch (this) {
      case EtapaCultivo.semilla:
        return 'Semilla';
      case EtapaCultivo.germinacion:
        return 'Germinación';
      case EtapaCultivo.crecimiento:
        return 'Crecimiento';
      case EtapaCultivo.floracion:
        return 'Floración';
      case EtapaCultivo.cosecha:
        return 'Cosecha';
    }
  }

  double get progreso => (index + 1) / EtapaCultivo.values.length;

  static EtapaCultivo desdeTexto(String texto) {
    return EtapaCultivo.values.firstWhere(
      (e) => e.name == texto,
      orElse: () => EtapaCultivo.semilla,
    );
  }
}