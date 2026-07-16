import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../database/db_helper.dart';
import '../../models/parcela.dart';

class ParcelaFormScreen extends StatefulWidget {
  final Parcela? parcela;

  const ParcelaFormScreen({super.key, this.parcela});

  @override
  State<ParcelaFormScreen> createState() => _ParcelaFormScreenState();
}

class _ParcelaFormScreenState extends State<ParcelaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _ubicacionController;
  late TextEditingController _areaController;

  String? _fotoPath;
  double? _latitud;
  double? _longitud;
  bool _obteniendoUbicacion = false;

  bool get _esEdicion => widget.parcela != null;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.parcela?.nombre ?? '');
    _ubicacionController =
        TextEditingController(text: widget.parcela?.ubicacion ?? '');
    _areaController = TextEditingController(
      text: widget.parcela != null
          ? widget.parcela!.areaHectareas.toString()
          : '',
    );

    _fotoPath = widget.parcela?.fotoPath;
    _latitud = widget.parcela?.latitud;
    _longitud = widget.parcela?.longitud;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // ---------------- FOTO ----------------

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // comprime un poco, para no ocupar tanto espacio
    );

    if (imagen == null) return; // el usuario canceló

    // Copiamos la foto a una carpeta permanente de la app,
    // porque el archivo temporal de la cámara puede borrarse después.
    final directorio = await getApplicationDocumentsDirectory();
    final nombreArchivo = p.basename(imagen.path);
    final rutaFinal = p.join(directorio.path, nombreArchivo);
    final archivoGuardado = await File(imagen.path).copy(rutaFinal);

    setState(() {
      _fotoPath = archivoGuardado.path;
    });
  }

  // ---------------- GPS ----------------

  Future<void> _obtenerUbicacion() async {
    setState(() => _obteniendoUbicacion = true);

    try {
      // 1. Verifica que el GPS del celular esté activado
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        _mostrarError('Activa el GPS de tu celular e intenta de nuevo');
        return;
      }

      // 2. Verifica/pide permiso de ubicación
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          _mostrarError('Permiso de ubicación denegado');
          return;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        _mostrarError(
          'Permiso de ubicación bloqueado. Actívalo desde ajustes del celular',
        );
        return;
      }

      // 3. Obtiene la posición actual
      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
        // Autocompleta el campo de texto "ubicación" con las coordenadas
        _ubicacionController.text =
            '${posicion.latitude.toStringAsFixed(6)}, ${posicion.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      _mostrarError('No se pudo obtener la ubicación');
    } finally {
      setState(() => _obteniendoUbicacion = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  // ---------------- GUARDAR ----------------

  Future<void> _guardar() async {
  if (!_formKey.currentState!.validate()) return;

  final parcela = Parcela(
    id: widget.parcela?.id,
    nombre: _nombreController.text.trim(),
    ubicacion: _ubicacionController.text.trim(),
    areaHectareas: double.parse(_areaController.text.trim()),
    fotoPath: _fotoPath,
    latitud: _latitud,
    longitud: _longitud,
  );

  try {
    if (_esEdicion) {
      await DBHelper.instance.updateParcela(parcela);
    } else {
      await DBHelper.instance.insertParcela(parcela);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_esEdicion ? 'Parcela actualizada ✅' : 'Parcela guardada ✅'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo guardar la parcela. Intenta de nuevo'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar parcela' : 'Nueva parcela'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ---------- Sección de foto ----------
              Center(
                child: GestureDetector(
                  onTap: _tomarFoto,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _fotoPath == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tomar foto', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_fotoPath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
              if (_fotoPath != null)
                Center(
                  child: TextButton.icon(
                    onPressed: _tomarFoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tomar otra foto'),
                  ),
                ),
              const SizedBox(height: 16),

              // ---------- Campos del formulario ----------
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Ingresa un nombre'
                        : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  suffixIcon: _obteniendoUbicacion
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location),
                          tooltip: 'Usar mi ubicación actual',
                          onPressed: _obtenerUbicacion,
                        ),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Ingresa una ubicación'
                        : null,
              ),
              if (_latitud != null && _longitud != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Lat: ${_latitud!.toStringAsFixed(6)} · Lng: ${_longitud!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _areaController,
                decoration:
                    const InputDecoration(labelText: 'Área (hectáreas)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el área';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardar,
                  child: Text(_esEdicion ? 'Actualizar' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}