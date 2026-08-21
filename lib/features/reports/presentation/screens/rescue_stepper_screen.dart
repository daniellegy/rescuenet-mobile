import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../history/domain/models/report_model.dart';
import '../../data/report_repository.dart';
import '../providers/active_reports_provider.dart';
import '../providers/my_active_rescue_provider.dart';
import '../../../map/presentation/providers/map_markers_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../providers/rescue_stepper_provider.dart';
import '../../../../core/services/camera_service.dart';
import '../widgets/canal_chat_sheet.dart';

class RescueStepperScreen extends ConsumerStatefulWidget {
  final ReportModel reporte;

  const RescueStepperScreen({super.key, required this.reporte});

  @override
  ConsumerState<RescueStepperScreen> createState() =>
      _RescueStepperScreenState();
}

class _RescueStepperScreenState extends ConsumerState<RescueStepperScreen> {
  bool _isLoading = false;
  late final TextEditingController _costoController;
  late final TextEditingController _conclusionController;
  final FocusNode _costoFocusNode = FocusNode();
  bool _canalCerradoLocalmente = false;

  final Map<String, Map<String, String>> _directorios = const {
    'Veterinaria': {
      'Clínica del perro callejero':
          'https://maps.app.goo.gl/inDv3ntFfgWKuCQd8',
      'Esterilizaciones Angeles Peludos':
          'https://maps.app.goo.gl/4PSVmUaeme9YkW5m7',
    },
    'Refugio': {
      'Fundación HOPE Puebla': 'https://maps.app.goo.gl/tHk7cf7EtkF6GLEMA',
      'Refugio Ángeles de la Clínica':
          'https://maps.app.goo.gl/yXZpFkuzSAoRLj8X8',
    },
  };

  @override
  void initState() {
    super.initState();
    final stepperState = ref.read(rescueStepperProvider);
    _costoController = TextEditingController(text: stepperState.costo);
    _conclusionController = TextEditingController(
      text: stepperState.conclusion,
    );
    _costoFocusNode.addListener(_onCostoFocusChanged);
  }

  @override
  void dispose() {
    _costoFocusNode.removeListener(_onCostoFocusChanged);
    _costoController.dispose();
    _conclusionController.dispose();
    _costoFocusNode.dispose();
    super.dispose();
  }

  void _onCostoFocusChanged() {
    if (!_costoFocusNode.hasFocus) {
      final text = _costoController.text.replaceAll(RegExp(r'[^\d.]'), '');
      if (text.isNotEmpty) {
        final numero = double.tryParse(text);
        if (numero != null) {
          final parts = numero.toStringAsFixed(2).split('.');
          final wholePart = parts[0].replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
          _costoController.text = '\$ $wholePart.${parts[1]}';
          ref
              .read(rescueStepperProvider.notifier)
              .updateField(cost: _costoController.text);
        }
      }
    }
  }

  Future<bool> _hayMensajesSinLeer() async {
    try {
      final mensajes = await ref
          .read(reportRepositoryProvider)
          .obtenerMensajesCanal(widget.reporte.id);
      if (mensajes.isEmpty) {
        return false;
      }
      final ultimoId = mensajes.last['id'] as int;
      final prefs = await SharedPreferences.getInstance();
      final leidoId = prefs.getInt('canal_leido_${widget.reporte.id}') ?? 0;
      return ultimoId > leidoId;
    } catch (_) {
      return false;
    }
  }

  Future<void> _lanzarUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _mostrarError('No se pudo abrir el enlace');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _tomarFotoEvidencia() async {
    final xFile = await ref.read(cameraServiceProvider).takePicture();
    if (xFile != null) {
      ref
          .read(rescueStepperProvider.notifier)
          .updateField(evidencia: xFile.path);
    }
  }

  Future<void> _confirmarTraslado() async {
    final estado = ref.read(rescueStepperProvider);
    if (estado.tipoTraslado == null || estado.lugarTraslado == null) {
      _mostrarError('Selecciona el lugar al que te diriges.');
      return;
    }

    try {
      await ref
          .read(reportRepositoryProvider)
          .updateProgress(
            widget.reporte.id,
            lugarTraslado: estado.lugarTraslado,
          );
      _invalidarProveedores();

      final url = _directorios[estado.tipoTraslado]![estado.lugarTraslado]!;
      await _lanzarUrl(url);

      ref
          .read(rescueStepperProvider.notifier)
          .updateField(step: estado.currentStep + 1);
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString());
      }
    }
  }

  Future<void> _finalizarRescate() async {
    final estado = ref.read(rescueStepperProvider);
    setState(() {
      _isLoading = true;
    });

    try {
      final costoLimpio = _costoController.text.replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );

      final detalles = {
        'condicion': estado.condicion ?? 'Desconocida',
        'destino': estado.destino,
        'costo': double.tryParse(costoLimpio) ?? 0.0,
        'conclusion': _conclusionController.text,
      };

      await ref
          .read(reportRepositoryProvider)
          .finalizeReport(widget.reporte.id, detalles, estado.evidenciaPath);

      ref.read(rescueStepperProvider.notifier).reset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Rescate exitoso!'),
            backgroundColor: Colors.green,
          ),
        );
        _invalidarProveedores();
        context.go('/map');
      }
    } catch (e) {
      if (mounted) {
        _mostrarError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _invalidarProveedores() {
    ref.invalidate(activeReportsProvider);
    ref.invalidate(miRescateActivoProvider);
    ref.invalidate(misReportesProvider);
    ref.invalidate(reportesActivosMapaProvider);
  }

  Future<bool> _validarPasoActual(int step, RescueStepperState state) async {
    switch (step) {
      case 0:
        if (state.animalPresente == null) {
          _mostrarError(
            'Por favor, indica si el animal se encuentra en el área.',
          );
          return false;
        }
        if (state.animalPresente == 'No') {
          _mostrarError(
            'Seleccionaste que no está. Puedes abortar el rescate desde el panel principal.',
          );
          return false;
        }
        try {
          await ref
              .read(reportRepositoryProvider)
              .updateProgress(widget.reporte.id, animalAvistado: true);
          ref.invalidate(miRescateActivoProvider);
        } catch (_) {}
        return true;
      case 1:
        if (state.condicion == null) {
          _mostrarError(
            'Por favor, selecciona la condición actual del animal.',
          );
          return false;
        }
        return true;
      case 3:
        if (state.lugarTraslado == null) {
          _mostrarError('Debes confirmar el lugar de traslado.');
          return false;
        }
        return true;
      case 4:
        if (state.evidenciaPath == null) {
          _mostrarError(
            'Es obligatorio tomar una fotografía como evidencia del rescate.',
          );
          return false;
        }
        return true;
      case 5:
        if (state.destino == null) {
          _mostrarError(
            'Por favor, selecciona el destino o ubicación final del animal.',
          );
          return false;
        }
        return true;
      case 6:
        if (_costoController.text.trim().isEmpty) {
          _mostrarError(
            'Por favor, indica el costo operativo. Si no hubo gastos, escribe 0.',
          );
          return false;
        }
        return true;
      case 7:
        if (_conclusionController.text.trim().isEmpty) {
          _mostrarError(
            'Por favor, ingresa una conclusión sobre el estado final del animal.',
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _procesarAvancePaso() async {
    final state = ref.read(rescueStepperProvider);
    final isStepValid = await _validarPasoActual(state.currentStep, state);

    if (!isStepValid) {
      return;
    }

    if (state.currentStep < 7) {
      ref
          .read(rescueStepperProvider.notifier)
          .updateField(
            step: state.currentStep + 1,
            cost: _costoController.text,
            concl: _conclusionController.text,
          );
    } else {
      await _finalizarRescate();
    }
  }

  void _procesarRetrocesoPaso() {
    final state = ref.read(rescueStepperProvider);
    if (state.currentStep > 0) {
      ref
          .read(rescueStepperProvider.notifier)
          .updateField(
            step: state.currentStep - 1,
            cost: _costoController.text,
            concl: _conclusionController.text,
          );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepperState = ref.watch(rescueStepperProvider);
    final notifier = ref.read(rescueStepperProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Suspender el proceso?'),
            content: const Text(
              'Se guardará tu progreso automáticamente. Puedes regresar a este menú más tarde en tu rescate activo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Asistente de Rescate'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              // Redirigimos explícitamente a los detalles de la emergencia
              context.pushReplacement('/report-detail', extra: widget.reporte);
            },
          ),
          actions: [
            if (widget.reporte.canalComunicacionHabilitado &&
                widget.reporte.canalComunicacionEstado == 'activo' &&
                !_canalCerradoLocalmente)
              FutureBuilder<bool>(
                future: _hayMensajesSinLeer(),
                builder: (context, snapshot) {
                  final hayNuevos = snapshot.data ?? false;
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        tooltip: 'Canal de comunicación',
                        onPressed: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useRootNavigator: true,
                            builder: (ctx) => CanalChatSheet(
                              reporteId: widget.reporte.id,
                              onCanalCerrado: () {
                                setState(() {
                                  _canalCerradoLocalmente = true;
                                });
                              },
                            ),
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      if (hayNuevos)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stepper(
                physics: const ClampingScrollPhysics(),
                currentStep: stepperState.currentStep,
                onStepContinue: _procesarAvancePaso,
                onStepCancel: _procesarRetrocesoPaso,
                controlsBuilder: (context, details) {
                  final isLast = stepperState.currentStep == 7;

                  if (stepperState.currentStep == 3 &&
                      stepperState.lugarTraslado == null) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        FilledButton(
                          onPressed: details.onStepContinue,
                          child: Text(
                            isLast ? 'Finalizar' : 'Siguiente',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (stepperState.currentStep > 0) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text(
                              'Volver',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: _buildSteps(stepperState, notifier),
              ),
      ),
    );
  }

  List<Step> _buildSteps(
    RescueStepperState state,
    RescueStepperNotifier notifier,
  ) {
    return [
      Step(
        title: const Text('1. Llegada y Avistamiento'),
        subtitle: const Text('Confirmación visual del reporte'),
        isActive: state.currentStep >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Llegaste a la ubicación y visualizaste al animal?'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Si', label: Text('Sí, aquí está')),
                  ButtonSegment(value: 'No', label: Text('No está en área')),
                ],
                selected: state.animalPresente != null
                    ? {state.animalPresente!}
                    : <String>{},
                emptySelectionAllowed: true,
                onSelectionChanged: (newSelection) {
                  if (newSelection.isNotEmpty) {
                    notifier.updateField(animal: newSelection.first);
                  }
                },
              ),
            ),
            if (state.animalPresente == 'Si')
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Prepárate con guantes, correa, transportadora y manta. Procede con precaución.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
      Step(
        title: const Text('2. Condiciones de Rescate'),
        subtitle: const Text('Evaluación del entorno y del animal'),
        isActive: state.currentStep >= 1,
        content: DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey(state.condicion),
          initialValue: state.condicion,
          hint: const Text('Selecciona una condición'),
          items: const [
            DropdownMenuItem(
              value: 'Accesible',
              child: Text('Accesible y dócil'),
            ),
            DropdownMenuItem(
              value: 'Atrapado / Encerrado',
              child: Text('Atrapado / Requiere herramientas'),
            ),
            DropdownMenuItem(
              value: 'Herido',
              child: Text('Herido / Requiere soporte médico inmediato'),
            ),
            DropdownMenuItem(
              value: 'Asustado',
              child: Text('Asustado / Riesgo de fuga'),
            ),
          ],
          onChanged: (v) => notifier.updateField(cond: v),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
      Step(
        title: const Text('3. Acción y Protocolo'),
        subtitle: const Text('Recomendaciones de seguridad'),
        isActive: state.currentStep >= 2,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            state.condicion == 'Herido'
                ? 'Manejo crítico: Usa guantes gruesos y manta para evitar mordeduras por dolor. Traslada con urgencia.'
                : state.condicion == 'Atrapado / Encerrado'
                ? 'Si requiere romper rejas o estructuras, solicita apoyo a bomberos. Si es seguro, usa correa de ahorque o pértiga.'
                : state.condicion == 'Asustado'
                ? 'No hagas movimientos bruscos. Acércate a nivel del suelo ofreciendo alimento y evita el contacto visual directo.'
                : 'Acércate despacio, háblale con voz suave y asegúralo con collar/correa o transportadora.',
            style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
          ),
        ),
      ),
      Step(
        title: const Text('4. Traslado (Directorio)'),
        subtitle: const Text('Selecciona el centro de apoyo destino'),
        isActive: state.currentStep >= 3,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Hacia dónde llevarás al animal para su evaluación?'),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Veterinaria', label: Text('Clínica')),
                ButtonSegment(value: 'Refugio', label: Text('Refugio')),
              ],
              selected: state.tipoTraslado != null
                  ? {state.tipoTraslado!}
                  : <String>{},
              emptySelectionAllowed: true,
              onSelectionChanged: (newSelection) {
                if (newSelection.isNotEmpty) {
                  notifier.updateField(tipoTras: newSelection.first);
                  notifier.clearLugarTraslado();
                }
              },
            ),
            if (state.tipoTraslado != null) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final opcionesValidas = _directorios[state.tipoTraslado]!.keys
                      .toList();
                  final valorSeguro =
                      opcionesValidas.contains(state.lugarTraslado)
                      ? state.lugarTraslado
                      : null;

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(valorSeguro),
                    initialValue: valorSeguro,
                    hint: const Text('Selecciona el lugar exacto'),
                    items: opcionesValidas
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => notifier.updateField(lugarTras: v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _confirmarTraslado,
                icon: const Icon(Icons.navigation),
                label: const Text('Confirmar y Navegar GPS'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
      Step(
        title: const Text('5. Evidencia de Rescate'),
        subtitle: const Text('Respaldo fotográfico oficial'),
        isActive: state.currentStep >= 4,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Toma una foto clara del animal ya asegurado en el vehículo o al llegar a las instalaciones correspondientes.',
            ),
            const SizedBox(height: 12),
            if (state.evidenciaPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.evidenciaPath!),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _tomarFotoEvidencia,
              icon: const Icon(Icons.camera_alt),
              label: Text(
                state.evidenciaPath != null
                    ? 'Reemplazar Fotografía'
                    : 'Abrir Cámara',
              ),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('6. Destino Final'),
        subtitle: const Text('Ubicación actual de resguardo'),
        isActive: state.currentStep >= 5,
        content: DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey(state.destino),
          initialValue: state.destino,
          hint: const Text('¿Dónde quedó resguardado el animal?'),
          items: const [
            DropdownMenuItem(
              value: 'Veterinaria',
              child: Text('Internado en Veterinaria'),
            ),
            DropdownMenuItem(
              value: 'Albergue / Refugio',
              child: Text('Aceptado en Refugio / Albergue'),
            ),
            DropdownMenuItem(
              value: 'Retención Temporal (Mi casa)',
              child: Text('En hogar temporal (Mi casa)'),
            ),
            DropdownMenuItem(
              value: 'Adoptado Inmediatamente',
              child: Text('Adoptado inmediatamente'),
            ),
            DropdownMenuItem(
              value: 'Fallecimiento',
              child: Text('Falleció durante traslado/atención'),
            ),
            DropdownMenuItem(
              value: 'Se escapó en el traslado',
              child: Text('Se escapó durante el traslado'),
            ),
          ],
          onChanged: (v) => notifier.updateField(dest: v),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
      Step(
        title: const Text('7. Costo Operativo'),
        subtitle: const Text('Gastos generados (MXN)'),
        isActive: state.currentStep >= 6,
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TextFormField(
            controller: _costoController,
            focusNode: _costoFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Costo Total (MXN)',
              helperText: 'Gastos médicos, gasolina o cuotas del refugio.',
              prefixIcon: Icon(Icons.attach_money),
              hintText: '\$ 0.00',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\$ ]')),
            ],
            onChanged: (v) => notifier.updateField(cost: v),
          ),
        ),
      ),
      Step(
        title: const Text('8. Conclusión Final'),
        subtitle: const Text('Resumen del caso'),
        isActive: state.currentStep >= 7,
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TextFormField(
            controller: _conclusionController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Estado médico y observaciones finales',
              hintText:
                  'Ej. Se encuentra estable internado en la clínica tras cirugía de emergencia.',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => notifier.updateField(concl: v),
          ),
        ),
      ),
    ];
  }
}
