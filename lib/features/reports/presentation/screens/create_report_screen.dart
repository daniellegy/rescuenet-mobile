import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../map/presentation/providers/map_markers_provider.dart';
import '../providers/active_reports_provider.dart';
import '../providers/create_report_provider.dart';
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
  'Otro',
];

final List<String> _razasGatos = [
  'Mestizo Pelo Corto',
  'Mestizo Pelo Largo',
  'Siamés',
  'Carey / Calicó',
  'Persa / Angora',
  'Otro gato de raza',
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
  'Otro',
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
  'Otro',
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
  final _referenciasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(createReportProvider.notifier);

      // GARANTÍA DE LIMPIEZA: Forzamos el reset justo al abrir la pantalla
      notifier.reset();
      notifier.setInitialLocation(widget.lat, widget.lng);
    });
  }

  @override
  void dispose() {
    _caracController.dispose();
    _referenciasController.dispose();
    super.dispose();
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(createReportProvider.notifier);

    try {
      await notifier.submitReport(
        imagePath: widget.imagePath,
        caracteristicas: _caracController.text,
        referencias: _referenciasController.text,
      );

      if (mounted) {
        // Limpiamos los controladores de texto por si acaso la vista se retiene
        _caracController.clear();
        _referenciasController.clear();

        ref.invalidate(reportesActivosMapaProvider);
        ref.invalidate(activeReportsProvider);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Completar Reporte')),
      body: state.isLoading
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
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationSelectorScreen(
                                initialLat: state.lat,
                                initialLng: state.lng,
                              ),
                            ),
                          );

                          if (result != null && result is Map<String, double>) {
                            notifier.updateLocation(
                              result['lat']!,
                              result['lng']!,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: state.especie,
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
                              child: Text(
                                e == 'Silvestre' ? 'Animal Silvestre' : e,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => notifier.updateField(especie: val),
                    ),
                    const SizedBox(height: 16),

                    if (state.especie != null) ...[
                      DropdownButtonFormField<String>(
                        value: state.razaSeleccionada,
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: InputDecoration(
                          labelText: state.especie == 'Silvestre'
                              ? 'Especie / Tipo de animal'
                              : 'Raza Aproximada',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        items:
                            (state.especie == 'Perro'
                                    ? _razasPerros
                                    : state.especie == 'Gato'
                                    ? _razasGatos
                                    : _silvestresPuebla)
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => notifier.updateField(raza: val),
                        validator: (value) => value == null
                            ? 'Por favor selecciona una opción'
                            : null,
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
                      selected: {state.urgenciaSeleccionada},
                      onSelectionChanged: (newSelection) =>
                          notifier.updateField(urgencia: newSelection.first),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return state.urgenciaSeleccionada == 'alta'
                                  ? Colors.red
                                  : state.urgenciaSeleccionada == 'media'
                                  ? Colors.orange
                                  : Colors.amber;
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.black87;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(state.urgenciaSeleccionada),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: state.urgenciaSeleccionada == 'alta'
                              ? Colors.red.shade50
                              : state.urgenciaSeleccionada == 'media'
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: state.urgenciaSeleccionada == 'alta'
                                ? Colors.red.shade200
                                : state.urgenciaSeleccionada == 'media'
                                ? Colors.orange.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              state.urgenciaSeleccionada == 'alta'
                                  ? Icons.warning_rounded
                                  : state.urgenciaSeleccionada == 'media'
                                  ? Icons.priority_high_rounded
                                  : Icons.health_and_safety_outlined,
                              color: state.urgenciaSeleccionada == 'alta'
                                  ? Colors.red
                                  : state.urgenciaSeleccionada == 'media'
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.urgenciaSeleccionada == 'alta'
                                        ? '🚨 Riesgo Vital / Flagrancia'
                                        : state.urgenciaSeleccionada == 'media'
                                        ? '⚠️ Atención Prioritaria'
                                        : '✅ Asistencia Diferida',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color:
                                          state.urgenciaSeleccionada == 'alta'
                                          ? Colors.red.shade900
                                          : state.urgenciaSeleccionada ==
                                                'media'
                                          ? Colors.orange.shade900
                                          : Colors.green.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.urgenciaSeleccionada == 'alta'
                                        ? 'Trauma severo, sangrado incontrolable, rescate técnico complejo o delito de crueldad en curso.'
                                        : state.urgenciaSeleccionada == 'media'
                                        ? 'Fauna silvestre desplazada, animal vulnerable (crías), o lesiones graves estables.'
                                        : 'Fauna deambulante estable, hacinamiento crónico, abandono sin intemperie extrema.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        ButtonSegment(
                          value: 200,
                          label: Text(
                            '200m\nCerrado',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ButtonSegment(
                          value: 500,
                          label: Text(
                            '500m\nColonia',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ButtonSegment(
                          value: 800,
                          label: Text(
                            '800m\nAmplio',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      selected: {state.radioSeleccionado},
                      onSelectionChanged: (newSelection) =>
                          notifier.updateField(radio: newSelection.first),
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
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.black87;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: state.colorSeleccionado,
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
                      onChanged: (val) => notifier.updateField(color: val),
                      validator: (value) => value == null
                          ? 'Por favor selecciona un color'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: state.sexo,
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
                      onChanged: (val) => notifier.updateField(sexo: val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: state.edad,
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
                      onChanged: (val) => notifier.updateField(edad: val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: state.tamano,
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
                      onChanged: (val) => notifier.updateField(tamano: val),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Nivel de Agresividad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: state.agresividad,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: state.agresividad.round().toString(),
                      activeColor: Colors.red,
                      onChanged: (val) =>
                          notifier.updateField(agresividad: val),
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
                      controller: _referenciasController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Referencias del lugar',
                        border: OutlineInputBorder(),
                        hintText: 'Ej. Junto al portón azul o local comercial',
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Por favor ingresa las referencias de la zona'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _enviarFormulario,
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
