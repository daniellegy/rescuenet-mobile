// Archivo: features/reports/presentation/screens/create_report_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../map/presentation/providers/map_markers_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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
  'Otro',
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
  final _razaPersonalizadaController = TextEditingController();

  final Set<String> _interactedDropdowns = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(createReportProvider.notifier);
      notifier.reset();
      notifier.setInitialLocation(widget.lat, widget.lng);
    });
  }

  @override
  void dispose() {
    _caracController.dispose();
    _referenciasController.dispose();
    _razaPersonalizadaController.dispose();
    super.dispose();
  }

  void _marcarInteraccion(String campo) {
    if (!_interactedDropdowns.contains(campo)) {
      setState(() {
        _interactedDropdowns.add(campo);
      });
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    IconData? prefixIcon,
    required bool isValid,
    required bool isEmpty,
    bool isNeutral = false,
    String? hintText,
  }) {
    Color borderColor = (isEmpty || isNeutral)
        ? Colors.grey
        : (isValid ? Colors.green.shade600 : Colors.red);
    Color iconColor = (isEmpty || isNeutral)
        ? Colors.grey.shade600
        : (isValid ? Colors.green.shade600 : Colors.red);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: borderColor),
      floatingLabelStyle: TextStyle(color: borderColor),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: iconColor)
          : null,
      suffixIcon: (isEmpty || isNeutral)
          ? null
          : Icon(isValid ? Icons.check_circle : Icons.error, color: iconColor),
      border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 2.0),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  Future<void> _enviarFormulario() async {
    if (_formKey.currentState?.validate() != true) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Por favor, completa todos los campos obligatorios.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final state = ref.read(createReportProvider);
    final perfil = ref.read(userProfileProvider).value;

    final double maxDistance = (perfil?['radio_notificaciones'] ?? 30) * 1000.0;
    final distance = Geolocator.distanceBetween(
      widget.lat,
      widget.lng,
      state.lat,
      state.lng,
    );

    if (distance > maxDistance) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No puedes crear reportes a más de ${maxDistance / 1000} km de distancia. Límite de tu configuración.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final notifier = ref.read(createReportProvider.notifier);

    try {
      await notifier.submitReport(
        imagePath: widget.imagePath,
        caracteristicas: _caracController.text,
        referencias: _referenciasController.text,
        razaPersonalizada: _razaPersonalizadaController.text,
      );

      if (mounted) {
        _caracController.clear();
        _referenciasController.clear();
        _razaPersonalizadaController.clear();

        ref.invalidate(reportesActivosMapaProvider);
        ref.invalidate(activeReportsProvider);

        context.pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte creado con éxito')),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        if (e.statusCode == 409) {
          _mostrarDialogoDuplicado();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _mostrarDialogoDuplicado() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Reporte duplicado')),
          ],
        ),
        content: const Text(
          'Parece que alguien ya reportó a un animal de la misma especie muy cerca de esta ubicación recientemente.\n\n¿Deseas ver las emergencias activas en tu mapa para confirmar si ya están pidiendo ayuda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cerrar aviso',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
              context.push('/active-reports');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Ver emergencias'),
          ),
        ],
      ),
    );
  }

  String _obtenerMensajeAgresividad(int nivel) {
    switch (nivel) {
      case 0:
        return 'Desconocido. Evite asumir docilidad y mantenga precaución estándar.';
      case 1:
        return 'Completamente dócil. No muestra ninguna señal de hostilidad.';
      case 2:
        return 'Tranquilo. Asustado, pero se deja manipular sin resistencia.';
      case 3:
        return 'Temeroso o evasivo. Se aleja e intenta esconderse si te aproximas.';
      case 4:
        return 'Nervioso. Puede gruñir levemente si se siente muy acorralado.';
      case 5:
        return 'Alerta y territorial. Mantiene la distancia emitiendo señales de aviso.';
      case 6:
        return 'Defensivo. Muestra los dientes o gruñe firmemente al acercarse.';
      case 7:
        return 'Reactivo. Lanza dentelladas al aire o intentos de rasguño si intentas tocarlo.';
      case 8:
        return 'Agresivo. Intenta morder o atacar de forma directa si invades su espacio.';
      case 9:
        return 'Altamente agresivo. Ataque activo e impredecible; muy difícil de contener.';
      case 10:
        return 'Peligro extremo. Agresión inminente; imposible de manipular sin equipo.';
      default:
        return 'Selecciona un nivel del 0 al 10.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Cancelar reporte?'),
            content: const Text(
              'Si sales ahora perderás toda la información registrada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No, continuar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sí, salir'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Completar Reporte')),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            if (result != null &&
                                result is Map<String, double>) {
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
                        key: ValueKey('especie_${state.especie}'),
                        initialValue: state.especie,
                        hint: const Text('Selecciona especie'),
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: _buildInputDecoration(
                          labelText: 'Especie',
                          prefixIcon: Icons.pets,
                          isValid: state.especie != null,
                          isEmpty: state.especie == null,
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
                        validator: (value) =>
                            value == null ? 'Selecciona una especie' : null,
                      ),
                      const SizedBox(height: 16),
                      if (state.especie != null) ...[
                        DropdownButtonFormField<String>(
                          key: ValueKey('raza_${state.razaSeleccionada}'),
                          initialValue: state.razaSeleccionada,
                          icon: const Icon(Icons.arrow_drop_down),
                          decoration: _buildInputDecoration(
                            labelText: state.especie == 'Silvestre'
                                ? 'Especie / Tipo de animal'
                                : 'Raza Aproximada',
                            prefixIcon: Icons.search,
                            isValid: state.razaSeleccionada != null,
                            isEmpty: state.razaSeleccionada == null,
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
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona una opción';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (state.razaSeleccionada == 'Otro') ...[
                          TextFormField(
                            controller: _razaPersonalizadaController,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                            decoration: _buildInputDecoration(
                              labelText: 'Especificar Raza / Especie',
                              prefixIcon: Icons.edit,
                              hintText: 'Ej. Cruza de pastor',
                              isValid: _razaPersonalizadaController.text
                                  .trim()
                                  .isNotEmpty,
                              isEmpty:
                                  _razaPersonalizadaController.text.isEmpty,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor escribe la raza o especie';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
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
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return state.urgenciaSeleccionada == 'alta'
                                      ? Colors.red
                                      : state.urgenciaSeleccionada == 'media'
                                      ? Colors.orange
                                      : Colors.amber;
                                }
                                return Colors.white;
                              }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.white;
                                }
                                return Colors.black87;
                              }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          key: ValueKey(
                            'urgencia_${state.urgenciaSeleccionada}',
                          ),
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
                                          ? 'Riesgo Vital'
                                          : state.urgenciaSeleccionada ==
                                                'media'
                                          ? 'Atención Prioritaria'
                                          : 'Asistencia Diferida',
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
                                          : state.urgenciaSeleccionada ==
                                                'media'
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
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.blue.shade700;
                                }
                                return Colors.white;
                              }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.white;
                                }
                                return Colors.black87;
                              }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey('color_${state.colorSeleccionado}'),
                        initialValue: state.colorSeleccionado,
                        hint: const Text('Selecciona Color Dominante'),
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: _buildInputDecoration(
                          labelText: 'Color Dominante',
                          prefixIcon: Icons.color_lens_outlined,
                          isValid: state.colorSeleccionado != null,
                          isEmpty: state.colorSeleccionado == null,
                        ),
                        items: _coloresGenerales
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) => notifier.updateField(color: val),
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor selecciona un color';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('sexo_${state.sexo}'),
                        initialValue: state.sexo,
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: _buildInputDecoration(
                          labelText: 'Sexo',
                          isValid: true,
                          isEmpty: false,
                          isNeutral: !_interactedDropdowns.contains('sexo'),
                        ),
                        items: ['Desconocido', 'Macho', 'Hembra']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) {
                          _marcarInteraccion('sexo');
                          notifier.updateField(sexo: val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('edad_${state.edad}'),
                        initialValue: state.edad,
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: _buildInputDecoration(
                          labelText: 'Edad',
                          isValid: true,
                          isEmpty: false,
                          isNeutral: !_interactedDropdowns.contains('edad'),
                        ),
                        items: ['Cachorro', 'Adulto', 'Senior']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) {
                          _marcarInteraccion('edad');
                          notifier.updateField(edad: val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('tamano_${state.tamano}'),
                        initialValue: state.tamano,
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: _buildInputDecoration(
                          labelText: 'Tamaño',
                          isValid: true,
                          isEmpty: false,
                          isNeutral: !_interactedDropdowns.contains('tamano'),
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
                        onChanged: (val) {
                          _marcarInteraccion('tamano');
                          notifier.updateField(tamano: val);
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Nivel de Agresividad',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: state.agresividad,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: state.agresividad.round().toString(),
                        activeColor: Colors.red,
                        onChanged: (val) =>
                            notifier.updateField(agresividad: val),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: state.agresividad >= 7
                                  ? Colors.red
                                  : Colors.blueGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _obtenerMensajeAgresividad(
                                  state.agresividad.round(),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _caracController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: _buildInputDecoration(
                          labelText: 'Características Especiales',
                          hintText: 'Ej. Sin cola, Heridas.',
                          isValid: _caracController.text.trim().isNotEmpty,
                          isEmpty: _caracController.text.isEmpty,
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) {
                            return 'Ingresa las características';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenciasController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: _buildInputDecoration(
                          labelText: 'Referencias del lugar',
                          hintText:
                              'Ej. Junto al portón azul o local comercial',
                          isValid: _referenciasController.text
                              .trim()
                              .isNotEmpty,
                          isEmpty: _referenciasController.text.isEmpty,
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) {
                            return 'Por favor ingresa las referencias de la zona';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 0,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                        child: SwitchListTile(
                          value: state.activarCanal,
                          onChanged: (val) => notifier.toggleActivarCanal(val),
                          title: const Text(
                            '¿Deseas activar el canal de comunicación?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Podrás chatear con el voluntario que tome tu caso. El canal se cerrará automáticamente cuando el caso se resuelva.',
                            style: TextStyle(fontSize: 12),
                          ),
                          activeThumbColor: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
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
      ),
    );
  }
}
