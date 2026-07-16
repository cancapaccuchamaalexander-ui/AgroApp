import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/registro_fertilizante.dart';

class FertilizanteFormScreen extends StatefulWidget {
  final int cultivoId;

  const FertilizanteFormScreen({super.key, required this.cultivoId});

  @override
  State<FertilizanteFormScreen> createState() =>
      _FertilizanteFormScreenState();
}

class _FertilizanteFormScreenState extends State<FertilizanteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _productoController = TextEditingController();
  final _dosisController = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _productoController.dispose();
    _dosisController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() => _fecha = fecha);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
  }

  Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) return;

  final fertilizante = RegistroFertilizante(
    cultivoId: widget.cultivoId,
    fecha: _formatearFecha(_fecha),
    producto: _productoController.text.trim(),
    dosis: double.parse(_dosisController.text.trim()),
  );

  try {
    await DBHelper.instance.insertFertilizante(fertilizante);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fertilizante guardado ✅'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo guardar el registro. Intenta de nuevo'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar fertilizante')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _productoController,
                decoration: const InputDecoration(labelText: 'Producto'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Ingresa el producto'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosisController,
                decoration: const InputDecoration(labelText: 'Dosis'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la dosis';
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
                title: const Text('Fecha de aplicación'),
                subtitle: Text(_formatearFecha(_fecha)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFecha,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}