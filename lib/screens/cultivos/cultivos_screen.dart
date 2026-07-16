import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/cultivo.dart';
import '../../models/parcela.dart';
import 'cultivo_form_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/etapa_progress_bar.dart';

class CultivosScreen extends StatefulWidget {
  const CultivosScreen({super.key});

  @override
  State<CultivosScreen> createState() => _CultivosScreenState();
}

class _CultivosScreenState extends State<CultivosScreen> {
  List<Cultivo> _cultivos = [];
  Map<int, String> _nombresParcelas = {}; // id parcela -> nombre, para mostrar
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final cultivos = await DBHelper.instance.getCultivos();
    final parcelas = await DBHelper.instance.getParcelas();

    setState(() {
      _cultivos = cultivos;
      _nombresParcelas = {for (var p in parcelas) p.id!: p.nombre};
      _cargando = false;
    });
  }

  Future<void> _eliminarCultivo(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cultivo'),
        content: const Text(
          '¿Seguro que deseas eliminar este cultivo? También se eliminarán sus registros de riego y fertilizante.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DBHelper.instance.deleteCultivo(id);
      _cargarDatos();
    }
  }

  Future<void> _irAFormulario({Cultivo? cultivo}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CultivoFormScreen(cultivo: cultivo),
      ),
    );

    if (resultado == true) {
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cultivos')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _cultivos.isEmpty
          ? const Center(child: Text('No hay cultivos registrados'))
          : ListView.builder(
              itemCount: _cultivos.length,
              itemBuilder: (context, index) {
                final cultivo = _cultivos[index];
                final nombreParcela =
                    _nombresParcelas[cultivo.parcelaId] ?? 'Sin parcela';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cultivo.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${cultivo.variedad} · Parcela: $nombreParcela',
                                  ),
                                  Text(
                                    'Sembrado: ${cultivo.fechaSiembra}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _irAFormulario(cultivo: cultivo),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.alerta),
                              onPressed: () => _eliminarCultivo(cultivo.id!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        EtapaProgressBar(etapa: cultivo.etapa),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irAFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
