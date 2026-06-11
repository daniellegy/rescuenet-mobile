import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/report_repository.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final double lat;
  final double lng;
  final String imagePath;

  const CreateReportScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.imagePath,
  });

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  final _razaController = TextEditingController();
  final _caracController = TextEditingController();
  final _notasController = TextEditingController();

  String? _especie;
  String? _sexo = 'Desconocido';
  String? _edad = 'Cachorro';
  String? _tamano = 'Pequeño';
  double _agresividad = 1.0; // Variable de la barra (Slider)
  bool _isLoading = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_especie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una especie.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(reportRepositoryProvider);

      await repository.createReport(
        lat: widget.lat,
        lng: widget.lng,
        especie: _especie!,
        color: _colorController.text,
        sexo: _sexo!,
        edadAprox: _edad!,
        tamano: _tamano!,
        agresividad: _agresividad
            .toInt(), // Corrección: Conversión directa a entero sin '!'
        razaAprox: _razaController.text,
        caracteristicasEspeciales: _caracController.text,
        notasAdicionales: _notasController.text,
        imagePath: widget.imagePath,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte creado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _razaController.dispose();
    _caracController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completar Reporte')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(widget.imagePath),
                        height: 250,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _especie,
                      hint: const Text('Selecciona especie'),
                      icon: const Icon(Icons.arrow_drop_down),
                      decoration: const InputDecoration(
                        labelText: 'Especie',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      items: ['Perro', 'Gato']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _especie = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Color Dominante',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.color_lens_outlined),
                        hintText: 'Ej. Naranjoso',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa el color' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _sexo,
                      icon: const Icon(Icons.arrow_drop_down),
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Desconocido', 'Macho', 'Hembra']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _sexo = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _edad,
                      icon: const Icon(Icons.arrow_drop_down),
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Cachorro', 'Adulto', 'Senior']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _edad = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tamano,
                      icon: const Icon(Icons.arrow_drop_down),
                      decoration: const InputDecoration(
                        labelText: 'Tamaño',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pequeño',
                          child: Text('Pequeño: Carga con una mano'),
                        ),
                        DropdownMenuItem(
                          value: 'Mediano',
                          child: Text('Mediano: Carga con dos manos'),
                        ),
                        DropdownMenuItem(
                          value: 'Grande',
                          child: Text('Grande: Requiere ayuda para cargar'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _tamano = val),
                    ),
                    const SizedBox(height: 24),

                    // Corrección: Slider y su texto
                    const Text(
                      'Nivel de Agresividad (1: Tranquilo - 10: Muy agresivo)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _agresividad,
                      min: 1,
                      max: 10,
                      divisions: 9, // Brinca en números enteros
                      label: _agresividad.round().toString(),
                      activeColor: Colors.red,
                      onChanged: (double value) {
                        setState(() {
                          _agresividad = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _razaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Raza Aproximada',
                        border: OutlineInputBorder(),
                        hintText: 'Ej. Desconocido, Mestizo, Husky',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa la raza' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caracController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Características Especiales',
                        border: OutlineInputBorder(),
                        hintText: 'Ej. Sin cola, Heridas.',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa las características' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notasController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Notas Adicionales',
                        border: OutlineInputBorder(),
                        hintText: 'Ej. Miedoso, Cojea de una pata',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa las notas' : null,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _submitReport,
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar Reporte'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
