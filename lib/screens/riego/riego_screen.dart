import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/cultivo.dart';
import '../../models/registro_riego.dart';
import '../../services/notificacion_service.dart';
import 'riego_form_screen.dart';
import '../../theme/app_theme.dart';

class RiegoScreen extends StatefulWidget {
  const RiegoScreen({super.key});

  @override
  State<RiegoScreen> createState() => _RiegoScreenState();
}

class _RiegoScreenState extends State<RiegoScreen> {
  List<Cultivo> _cultivos = [];
  int? _cultivoSeleccionado;
  List<RegistroRiego> _riegos = [];
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

    // Si ya había un cultivo seleccionado, recarga sus riegos
    if (_cultivoSeleccionado != null) {
      _cargarRiegos(_cultivoSeleccionado!);
    }
  }

  Future<void> _cargarRiegos(int cultivoId) async {
    final riegos = await DBHelper.instance.getRiegosPorCultivo(cultivoId);
    setState(() {
      _cultivoSeleccionado = cultivoId;
      _riegos = riegos;
    });
  }

  Future<void> _eliminarRiego(RegistroRiego riego) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro de riego'),
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
      if (riego.notificacionId != null) {
        await NotificationService.instance.cancelarNotificacion(
          riego.notificacionId!,
        );
      }
      await DBHelper.instance.deleteRiego(riego.id!);
      _cargarRiegos(_cultivoSeleccionado!);
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
        builder: (context) => RiegoFormScreen(cultivoId: _cultivoSeleccionado!),
      ),
    );

    if (resultado == true) {
      _cargarRiegos(_cultivoSeleccionado!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de riego')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Selector de cultivo
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
                            if (value != null) _cargarRiegos(value);
                          },
                        ),
                  const SizedBox(height: 16),

                  // Historial de riegos del cultivo seleccionado
                  if (_cultivoSeleccionado != null)
                    Expanded(
                      child: _riegos.isEmpty
                          ? const Center(
                              child: Text('No hay riegos registrados aún'),
                            )
                          : ListView.builder(
                              itemCount: _riegos.length,
                              itemBuilder: (context, index) {
                                final riego = _riegos[index];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.water_drop,
                                      color: AppColors.agua,
                                    ),
                                    title: Text('${riego.cantidadAgua} litros'),
                                    subtitle: Text('Fecha: ${riego.fecha}'),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppColors.alerta,
                                      ), 
                                      onPressed: () => _eliminarRiego(riego),
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
