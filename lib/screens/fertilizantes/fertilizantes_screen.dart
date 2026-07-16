import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/cultivo.dart';
import '../../models/registro_fertilizante.dart';
import 'fertilizante_form_screen.dart';
import '../../theme/app_theme.dart';

class FertilizantesScreen extends StatefulWidget {
  const FertilizantesScreen({super.key});

  @override
  State<FertilizantesScreen> createState() => _FertilizantesScreenState();
}

class _FertilizantesScreenState extends State<FertilizantesScreen> {
  List<Cultivo> _cultivos = [];
  int? _cultivoSeleccionado;
  List<RegistroFertilizante> _fertilizantes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCultivos();
  }

  Future<void> _cargarCultivos() async {
    setState(() => _cargando = true);
    final cultivos = await DBHelper.instance.getCultivos();
    setState(() {
      _cultivos = cultivos;
      _cargando = false;
    });

    if (_cultivoSeleccionado != null) {
      _cargarFertilizantes(_cultivoSeleccionado!);
    }
  }

  Future<void> _cargarFertilizantes(int cultivoId) async {
    final data = await DBHelper.instance.getFertilizantesPorCultivo(cultivoId);
    setState(() {
      _cultivoSeleccionado = cultivoId;
      _fertilizantes = data;
    });
  }

  Future<void> _eliminarFertilizante(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Seguro que deseas eliminar este registro?'),
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
      await DBHelper.instance.deleteFertilizante(id);
      _cargarFertilizantes(_cultivoSeleccionado!);
    }
  }

  Future<void> _irAFormulario() async {
    if (_cultivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cultivo primero')),
      );
      return;
    }

    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FertilizanteFormScreen(cultivoId: _cultivoSeleccionado!),
      ),
    );

    if (resultado == true) {
      _cargarFertilizantes(_cultivoSeleccionado!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de fertilizantes')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cultivos.isEmpty
                      ? const Text(
                          'No hay cultivos registrados. Crea uno primero.',
                          style: TextStyle(color: Colors.red),
                        )
                      : DropdownButtonFormField<int>(
                          value: _cultivoSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Selecciona un cultivo',
                            border: OutlineInputBorder(),
                          ),
                          items: _cultivos.map((cultivo) {
                            return DropdownMenuItem(
                              value: cultivo.id,
                              child: Text(cultivo.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) _cargarFertilizantes(value);
                          },
                        ),
                  const SizedBox(height: 16),
                  if (_cultivoSeleccionado != null)
                    Expanded(
                      child: _fertilizantes.isEmpty
                          ? const Center(child: Text('No hay registros aún'))
                          : ListView.builder(
                              itemCount: _fertilizantes.length,
                              itemBuilder: (context, index) {
                                final fert = _fertilizantes[index];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.science,
                                      color: AppColors.fertilizante,
                                    ),
                                    title: Text(fert.producto),
                                    subtitle: Text(
                                      'Dosis: ${fert.dosis} · Fecha: ${fert.fecha}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppColors.alerta,
                                      ), // antes: Colors.red
                                      onPressed: () =>
                                          _eliminarFertilizante(fert.id!),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irAFormulario,
        child: const Icon(Icons.add),
      ),
    );
  }
}
