import 'package:flutter/material.dart';
import '../models/etapa_cultivo.dart';
import '../theme/app_theme.dart';

class EtapaProgressBar extends StatelessWidget {
  final EtapaCultivo etapa;

  const EtapaProgressBar({super.key, required this.etapa});

  Color _colorPorEtapa(EtapaCultivo etapa) {
  switch (etapa) {
    case EtapaCultivo.semilla:
      return AppColors.tierra;        // antes: Colors.brown
    case EtapaCultivo.germinacion:
      return AppColors.primaryLight;  // antes: Colors.lightGreen
    case EtapaCultivo.crecimiento:
      return AppColors.primary;       // antes: Colors.green
    case EtapaCultivo.floracion:
      return const Color(0xFFD81B60); // rosa floración (puedes dejarlo fijo, no está en AppColors)
    case EtapaCultivo.cosecha:
      return AppColors.fertilizante;  // antes: Colors.orange
  }
}

  @override
  Widget build(BuildContext context) {
    final color = _colorPorEtapa(etapa);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              etapa.etiqueta,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color),
            ),
            Text(
              '${(etapa.progreso * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: etapa.progreso,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}