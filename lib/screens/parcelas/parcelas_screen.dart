import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/parcela.dart';
import 'parcela_form_screen.dart';
import 'dart:io';
import '../../services/wheather_service.dart';
import '../../services/notificacion_service.dart';
import '../../theme/app_theme.dart';

class ParcelasScreen extends StatefulWidget {
  const ParcelasScreen({super.key});

  @override
  State<ParcelasScreen> createState() => _ParcelasScreenState();
}

class _ParcelasScreenState extends State<ParcelasScreen> {
  List<Parcela> _parcelas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarParcelas();
  }

  Future<void> _cargarParcelas() async {
    setState(() => _cargando = true);
    final data = await DBHelper.instance.getParcelas();
    setState(() {
      _parcelas = data;
      _cargando = false;
    });
  }

  Future<void> _eliminarParcela(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar parcela'),
        content: const Text(
          '¿Seguro que deseas eliminar esta parcela? También se eliminarán sus cultivos y registros asociados.',
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
      await DBHelper.instance.deleteParcela(id);
      _cargarParcelas();
    }
  }

  Future<void> _irAFormulario({Parcela? parcela}) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelaFormScreen(parcela: parcela),
      ),
    );

    if (resultado == true) {
      _cargarParcelas();
    }
  }

  Future<void> _verClima(Parcela parcela) async {
    if (parcela.latitud == null || parcela.longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta parcela no tiene ubicación GPS guardada'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pronostico = await WeatherService.instance.obtenerPronostico(
        parcela.latitud!,
        parcela.longitud!,
      );
      final alertas = WeatherService.instance.analizarAlertas(pronostico);

      if (mounted) Navigator.pop(context); // cierra el loading

      // Notificación push por cada alerta crítica encontrada
      for (final alerta in alertas) {
        await NotificationService.instance.mostrarNotificacionInmediata(
          titulo: '⚠️ Alerta climática: ${alerta.tipo}',
          cuerpo: alerta.mensaje,
        );
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Clima · ${parcela.nombre}'),
          content: alertas.isEmpty
              ? const Text('No hay riesgos climáticos previstos esta semana ✅')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: alertas
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('⚠️ ${a.mensaje}'),
                        ),
                      )
                      .toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el clima. Verifica tu conexión'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parcelas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _parcelas.isEmpty
          ? const Center(child: Text('No hay parcelas registradas'))
          : ListView.builder(
              itemCount: _parcelas.length,
              itemBuilder: (context, index) {
                final parcela = _parcelas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: parcela.fotoPath != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(File(parcela.fotoPath!)),
                          )
                        : const CircleAvatar(child: Icon(Icons.map)),
                    title: Text(parcela.nombre),
                    subtitle: Text(
                      '${parcela.ubicacion} · ${parcela.areaHectareas} ha',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.cloud, color: AppColors.agua),
                          tooltip: 'Ver alertas climáticas',
                          onPressed: () => _verClima(parcela),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _irAFormulario(parcela: parcela),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.alerta),
                          onPressed: () => _eliminarParcela(parcela.id!),
                        ),
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
