import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/cultivo.dart';
import '../../models/parcela.dart';
import '../../models/etapa_cultivo.dart';

class CultivoFormScreen extends StatefulWidget {
  final Cultivo? cultivo;

  const CultivoFormScreen({super.key, this.cultivo});

  @override
  State<CultivoFormScreen> createState() => _CultivoFormScreenState();
}

class _CultivoFormScreenState extends State<CultivoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _variedadController;
  late TextEditingController _fechaController;

  List<Parcela> _parcelas = [];
  int? _parcelaSeleccionada;
  EtapaCultivo _etapaSeleccionada = EtapaCultivo.semilla;

  bool get _esEdicion => widget.cultivo != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.cultivo?.nombre ?? '',
    );
    _variedadController = TextEditingController(
      text: widget.cultivo?.variedad ?? '',
    );
    _fechaController = TextEditingController(
      text: widget.cultivo?.fechaSiembra ?? '',
    );

    _parcelaSeleccionada = widget.cultivo?.parcelaId;
    _etapaSeleccionada = widget.cultivo?.etapa ?? EtapaCultivo.semilla;

    _cargarParcelas();
  }

  Future<void> _cargarParcelas() async {
    final parcelas = await DBHelper.instance.getParcelas();
    setState(() => _parcelas = parcelas);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _variedadController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      _fechaController.text =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) return;

  if (_parcelaSeleccionada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona una parcela')),
    );
    return;
  }

  final cultivo = Cultivo(
    id: widget.cultivo?.id,
    parcelaId: _parcelaSeleccionada!,
    nombre: _nombreController.text.trim(),
    variedad: _variedadController.text.trim(),
    fechaSiembra: _fechaController.text.trim(),
    etapa: _etapaSeleccionada,
  );

  try {
    if (_esEdicion) {
      await DBHelper.instance.updateCultivo(cultivo);
    } else {
      await DBHelper.instance.insertCultivo(cultivo);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_esEdicion ? 'Cultivo actualizado ✅' : 'Cultivo guardado ✅'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo guardar el cultivo. Intenta de nuevo'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar cultivo' : 'Nuevo cultivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown de parcelas
              _parcelas.isEmpty
                  ? const Text(
                      'No hay parcelas creadas. Crea una parcela primero.',
                      style: TextStyle(color: Colors.red),
                    )
                  : DropdownButtonFormField<int>(
                      value: _parcelaSeleccionada,
                      decoration: const InputDecoration(labelText: 'Parcela'),
                      items: _parcelas.map((parcela) {
                        return DropdownMenuItem(
                          value: parcela.id,
                          child: Text(parcela.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _parcelaSeleccionada = value);
                      },
                    ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cultivo',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _variedadController,
                decoration: const InputDecoration(labelText: 'Variedad'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha de siembra',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _seleccionarFecha,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Selecciona una fecha'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EtapaCultivo>(
                value: _etapaSeleccionada,
                decoration: const InputDecoration(labelText: 'Etapa'),
                items: EtapaCultivo.values.map((etapa) {
                  return DropdownMenuItem(
                    value: etapa,
                    child: Text(etapa.etiqueta),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _etapaSeleccionada = value!);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardar,
                child: Text(_esEdicion ? 'Actualizar' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
