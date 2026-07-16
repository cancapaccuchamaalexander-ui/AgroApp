import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/registro_riego.dart';
import '../../services/notificacion_service.dart'; // 👈 nuevo import

class RiegoFormScreen extends StatefulWidget {
  final int cultivoId;

  const RiegoFormScreen({super.key, required this.cultivoId});

  @override
  State<RiegoFormScreen> createState() => _RiegoFormScreenState();
}

class _RiegoFormScreenState extends State<RiegoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cantidadController = TextEditingController();
  DateTime _fechaRiego = DateTime.now();

  // Para el recordatorio (se activará por completo en el paso 5)
  bool _programarRecordatorio = false;
  TimeOfDay _horaRecordatorio = const TimeOfDay(hour: 7, minute: 0);

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaRiego,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() => _fechaRiego = fecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaRecordatorio,
    );
    if (hora != null) {
      setState(() => _horaRecordatorio = hora);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    int? notificacionId;

    if (_programarRecordatorio) {
      final fechaHoraRecordatorio = DateTime(
        _fechaRiego.year,
        _fechaRiego.month,
        _fechaRiego.day,
        _horaRecordatorio.hour,
        _horaRecordatorio.minute,
      );

      notificacionId = await NotificationService.instance.programarNotificacion(
        titulo: 'Recordatorio de riego',
        cuerpo: 'Es hora de regar tu cultivo',
        fechaHora: fechaHoraRecordatorio,
      );
    }

    final riego = RegistroRiego(
      cultivoId: widget.cultivoId,
      fecha: _formatearFecha(_fechaRiego),
      cantidadAgua: double.parse(_cantidadController.text.trim()),
      notificacionId: notificacionId,
    );

    await DBHelper.instance.insertRiego(riego);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _programarRecordatorio
              ? 'Riego guardado y recordatorio programado ✅'
              : 'Riego guardado ✅',
        ),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo guardar el riego. Intenta de nuevo'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar riego')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de agua (litros)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la cantidad de agua';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de riego'),
                subtitle: Text(_formatearFecha(_fechaRiego)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFecha,
              ),
              const Divider(),

              // Sección de recordatorio (se conectará al paso 5)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Programar recordatorio de próximo riego'),
                value: _programarRecordatorio,
                onChanged: (value) {
                  setState(() => _programarRecordatorio = value);
                },
              ),
              if (_programarRecordatorio)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hora del recordatorio'),
                  subtitle: Text(_horaRecordatorio.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: _seleccionarHora,
                ),

              const SizedBox(height: 24),
              ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
