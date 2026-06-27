import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/report_repository.dart';

import 'location_selector_screen.dart';

final List<String> _razasPerros = [
  'Mestizo',
  'Pitbull',
  'Husky',
  'Poodle',
  'Chihuahua',
  'Pastor Alemán',
  'Labrador',
  'Pug',
  'Schnauzer',
  'Otro'
];

final List<String> _razasGatos = [
  'Mestizo Pelo Corto',
  'Mestizo Pelo Largo',
  'Siamés',
  'Carey / Calicó',
  'Persa / Angora',
  'Otro gato de raza'
];

final List<String> _silvestresPuebla = [
  'Tlacuache',
  'Cacomixtle',
  'Ardilla gris',
  'Ave de presa (Búho/Lechuza)',
  'Ave pequeña',
  'Murciélago',
  'Reptil / Serpiente',
  'Zorro gris',
  'Conejo silvestre',
  'Otro'
];

final List<String> _coloresGenerales = [
  'Negro',
  'Blanco',
  'Gris',
  'Café / Marrón',
  'Atigrado',
  'Miel / Canela',
  'Manchado / Bicolor',
  'Crema / Arena',
  'Otro'
];

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

  final _caracController = TextEditingController();
  final _notasController = TextEditingController();

  String _urgenciaSeleccionada = 'media';
  int _radioSeleccionado = 500;
  String? _especie;

  String? _razaSeleccionada; 
  String? _colorSeleccionado;
  
  String? _sexo = 'Desconocido';
  String? _edad = 'Cachorro';
  String? _tamano = 'Pequeño';
  double _agresividad = 1.0;
  bool _isLoading = false;

  late double _currentLat;
  late double _currentLng;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.lat;
    _currentLng = widget.lng;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_especie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una especie.')),
      );
      return;
    }
    
    if (_razaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una raza o tipo de animal.')),
      );
      return;
    }

    if (_colorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un color dominante.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(reportRepositoryProvider);

      await repository.createReport(
        lat: _currentLat, // Usamos la variable de estado actual
        lng: _currentLng, // Usamos la variable de estado actual
        especie: _especie!,
        color: _colorSeleccionado!,
        sexo: _sexo!,
        edadAprox: _edad!,
        tamano: _tamano!,
        agresividad: _agresividad.toInt(),
        
        razaAprox: _razaSeleccionada!, 
        caracteristicasEspeciales: _caracController.text,
        notasAdicionales: _notasController.text,
        urgencia: _urgenciaSeleccionada,
        imagePath: widget.imagePath,
        radio: _radioSeleccionado,
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

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 32,
                        ),
                        title: const Text(
                          'Ubicación del reporte',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'Toca para ajustar el PIN en el mapa',
                        ),
                        trailing: const Icon(
                          Icons.edit_location_alt,
                          color: Colors.blue,
                        ),
                        onTap: () async {
                          // Navegamos a la pantalla del mapa
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationSelectorScreen(
                                initialLat: _currentLat,
                                initialLng: _currentLng,
                              ),
                            ),
                          );

                          // Si el usuario confirma una ubicación, actualizamos el estado
                          if (result != null && result is Map<String, double>) {
                            setState(() {
                              _currentLat = result['lat']!;
                              _currentLng = result['lng']!;
                            });
                          }
                        },
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
                      items: ['Perro', 'Gato', 'Silvestre']
                          .map(
                            (e) => DropdownMenuItem(
                              value: e, 
                              child: Text(e == 'Silvestre' ? 'Animal Silvestre' : e),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _especie = val;
                          _razaSeleccionada = null; 
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_especie != null) ...[
                      DropdownButtonFormField<String>(
                        value: _razaSeleccionada,
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: InputDecoration(
                          labelText: _especie == 'Silvestre'
                              ? 'Especie / Tipo de animal'
                              : 'Raza Aproximada',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        items: (_especie == 'Perro'
                                ? _razasPerros
                                : _especie == 'Gato'
                                    ? _razasGatos
                                    : _silvestresPuebla)
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _razaSeleccionada = val),
                        validator: (value) =>
                            value == null ? 'Por favor selecciona una opción' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Nivel de Urgencia',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'baja', label: Text('Baja')),
                        ButtonSegment(value: 'media', label: Text('Media')),
                        ButtonSegment(value: 'alta', label: Text('Alta')),
                      ],
                      selected: {_urgenciaSeleccionada},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _urgenciaSeleccionada = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return _urgenciaSeleccionada == 'alta'
                                  ? Colors.red
                                  : _urgenciaSeleccionada == 'media'
                                  ? Colors.orange
                                  : Colors.amber;
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected))
                              return Colors.white;
                            return Colors.black87;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Radio de Búsqueda Recomendado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 200, label: Text('200m\nCerrado', textAlign: TextAlign.center)),
                        ButtonSegment(value: 500, label: Text('500m\nColonia', textAlign: TextAlign.center)),
                        ButtonSegment(value: 800, label: Text('800m\nAmplio', textAlign: TextAlign.center)),
                      ],
                      selected: {_radioSeleccionado},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _radioSeleccionado = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.blue.shade700;
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected))
                              return Colors.white;
                            return Colors.black87;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _colorSeleccionado,
                      hint: const Text('Selecciona Color Dominante'),
                      icon: const Icon(Icons.arrow_drop_down),
                      decoration: const InputDecoration(
                        labelText: 'Color Dominante',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.color_lens_outlined),
                      ),
                      items: _coloresGenerales
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _colorSeleccionado = val),
                      validator: (value) =>
                          value == null ? 'Por favor selecciona un color' : null,
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
                    const Text(
                      'Nivel de Agresividad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _agresividad,
                      min: 1,
                      max: 10,
                      divisions: 9,
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
                        labelText: 'Descripción del entorno',
                        border: OutlineInputBorder(),
                        hintText: 'Ej. Frente a tienda, escuela',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa la descripción' : null,
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