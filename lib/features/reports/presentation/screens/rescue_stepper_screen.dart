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
  late TextEditingController _costoController;
  late TextEditingController _conclusionController;
  final FocusNode _costoFocusNode = FocusNode();
  bool _canalCerradoLocalmente = false;

  final Map<String, Map<String, String>> _directorios = {
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

    // LÓGICA DE FORMATO DE MONEDA MXN ($ 0,000.00)
    _costoFocusNode.addListener(() {
      if (!_costoFocusNode.hasFocus) {
        String text = _costoController.text.replaceAll(RegExp(r'[^\d.]'), '');
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
    });
  }

  @override
  void dispose() {
    _costoController.dispose();
    _conclusionController.dispose();
    _costoFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _hayMensajesSinLeer() async {
    try {
      final mensajes = await ref
          .read(reportRepositoryProvider)
          .obtenerMensajesCanal(widget.reporte.id);
      if (mensajes.isEmpty) return false;
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
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el lugar al que te diriges.')),
      );
      return;
    }

    try {
      await ref
          .read(reportRepositoryProvider)
          .updateProgress(
            widget.reporte.id,
            lugarTraslado: estado.lugarTraslado,
          );

      ref.invalidate(miRescateActivoProvider);
      ref.invalidate(activeReportsProvider);
      ref.invalidate(reportesActivosMapaProvider);

      final url = _directorios[estado.tipoTraslado]![estado.lugarTraslado]!;
      await _lanzarUrl(url);

      ref
          .read(rescueStepperProvider.notifier)
          .updateField(step: estado.currentStep + 1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _finalizarRescate() async {
    final estado = ref.read(rescueStepperProvider);
    if (estado.destino == null ||
        _conclusionController.text.trim().isEmpty ||
        estado.evidenciaPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La evidencia, destino y conclusión son obligatorios.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Remover formato de moneda antes de enviar a DB
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
        ref.invalidate(activeReportsProvider);
        ref.invalidate(miRescateActivoProvider);
        ref.invalidate(misReportesProvider);
        ref.invalidate(reportesActivosMapaProvider);
        context.go('/map');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepperState = ref.watch(rescueStepperProvider);
    final notifier = ref.read(rescueStepperProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Rescate'),
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
                          builder: (ctx) => CanalChatSheet(
                            reporteId: widget.reporte.id,
                            onCanalCerrado: () =>
                                setState(() => _canalCerradoLocalmente = true),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                    if (hayNuevos)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 12,
                          height: 12,
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
              onStepContinue: () async {
                if (stepperState.currentStep == 0) {
                  if (stepperState.animalPresente == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, indica si el animal se encuentra en el área.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (stepperState.animalPresente == 'No') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Seleccionaste que no está. Puedes abortar el rescate desde el panel principal.',
                        ),
                      ),
                    );
                    return;
                  }
                  try {
                    await ref
                        .read(reportRepositoryProvider)
                        .updateProgress(
                          widget.reporte.id,
                          animalAvistado: true,
                        );
                    ref.invalidate(miRescateActivoProvider);
                  } catch (_) {}
                }
                if (stepperState.currentStep == 1) {
                  if (stepperState.condicion == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, selecciona la condición actual del animal.',
                        ),
                      ),
                    );
                    return;
                  }
                }
                if (stepperState.currentStep == 3) {
                  if (stepperState.lugarTraslado == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debes confirmar el lugar de traslado.'),
                      ),
                    );
                    return;
                  }
                }
                if (stepperState.currentStep == 4) {
                  if (stepperState.evidenciaPath == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Es obligatorio tomar una fotografía como evidencia del rescate.',
                        ),
                      ),
                    );
                    return;
                  }
                }
                if (stepperState.currentStep == 5) {
                  if (stepperState.destino == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, selecciona el destino o ubicación final del animal.',
                        ),
                      ),
                    );
                    return;
                  }
                }
                if (stepperState.currentStep == 6) {
                  if (_costoController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, indica el costo operativo. Si no hubo gastos, escribe 0.',
                        ),
                      ),
                    );
                    return;
                  }
                }
                if (stepperState.currentStep == 7) {
                  if (_conclusionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Por favor, ingresa una conclusión sobre el estado final del animal.',
                        ),
                      ),
                    );
                    return;
                  }
                }

                if (stepperState.currentStep < 7) {
                  notifier.updateField(
                    step: stepperState.currentStep + 1,
                    cost: _costoController.text,
                    concl: _conclusionController.text,
                  );
                } else {
                  _finalizarRescate();
                }
              },
              onStepCancel: () {
                if (stepperState.currentStep > 0) {
                  notifier.updateField(
                    step: stepperState.currentStep - 1,
                    cost: _costoController.text,
                    concl: _conclusionController.text,
                  );
                } else {
                  context.pop();
                }
              },
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
                        child: Text(isLast ? 'Finalizar' : 'Siguiente'),
                      ),
                      if (stepperState.currentStep > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Volver'),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('1. Llegada y Avistamiento'),
                  subtitle: const Text('Confirmación visual del reporte'),
                  isActive: stepperState.currentStep >= 0,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¿Llegaste a la ubicación y visualizaste al animal?',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Si',
                              label: Text('Sí, aquí está'),
                            ),
                            ButtonSegment(
                              value: 'No',
                              label: Text('No está en área'),
                            ),
                          ],
                          selected: stepperState.animalPresente != null
                              ? {stepperState.animalPresente!}
                              : <String>{},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (Set<String> newSelection) {
                            if (newSelection.isNotEmpty) {
                              notifier.updateField(animal: newSelection.first);
                            }
                          },
                        ),
                      ),
                      if (stepperState.animalPresente == 'Si')
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
                  isActive: stepperState.currentStep >= 1,
                  content: DropdownButtonFormField<String>(
                    isExpanded: true, // PREVIENE EL OVERFLOW DE TEXTO LARGO
                    key: ValueKey(stepperState.condicion),
                    value: stepperState.condicion,
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
                        child: Text(
                          'Herido / Requiere soporte médico inmediato',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Asustado',
                        child: Text('Asustado / Riesgo de fuga'),
                      ),
                    ],
                    onChanged: (v) => notifier.updateField(cond: v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Step(
                  title: const Text('3. Acción y Protocolo'),
                  subtitle: const Text('Recomendaciones de seguridad'),
                  isActive: stepperState.currentStep >= 2,
                  content: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stepperState.condicion == 'Herido'
                          ? 'Manejo crítico: Usa guantes gruesos y manta para evitar mordeduras por dolor. Traslada con urgencia.'
                          : stepperState.condicion == 'Atrapado / Encerrado'
                          ? 'Si requiere romper rejas o estructuras, solicita apoyo a bomberos. Si es seguro, usa correa de ahorque o pértiga.'
                          : stepperState.condicion == 'Asustado'
                          ? 'No hagas movimientos bruscos. Acércate a nivel del suelo ofreciendo alimento y evita el contacto visual directo.'
                          : 'Acércate despacio, háblale con voz suave y asegúralo con collar/correa o transportadora.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ),
                Step(
                  title: const Text('4. Traslado (Directorio)'),
                  subtitle: const Text('Selecciona el centro de apoyo destino'),
                  isActive: stepperState.currentStep >= 3,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '¿Hacia dónde llevarás al animal para su evaluación?',
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Veterinaria',
                            label: Text('Clínica'),
                          ),
                          ButtonSegment(
                            value: 'Refugio',
                            label: Text('Refugio'),
                          ),
                        ],
                        selected: stepperState.tipoTraslado != null
                            ? {stepperState.tipoTraslado!}
                            : <String>{},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (Set<String> newSelection) {
                          if (newSelection.isNotEmpty) {
                            notifier.updateField(tipoTras: newSelection.first);
                            notifier.clearLugarTraslado();
                          }
                        },
                      ),
                      if (stepperState.tipoTraslado != null) ...[
                        const SizedBox(height: 12),
                        WidgetRefBuilder(
                          builder: (context) {
                            final opcionesValidas =
                                _directorios[stepperState.tipoTraslado]!.keys
                                    .toList();
                            final String? valorSeguro =
                                opcionesValidas.contains(
                                  stepperState.lugarTraslado,
                                )
                                ? stepperState.lugarTraslado
                                : null;
                            return DropdownButtonFormField<String>(
                              isExpanded:
                                  true, // PREVIENE EL OVERFLOW DE TEXTO LARGO
                              key: ValueKey(valorSeguro),
                              value: valorSeguro,
                              hint: const Text('Selecciona el lugar exacto'),
                              items: opcionesValidas
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  notifier.updateField(lugarTras: v),
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
                  isActive: stepperState.currentStep >= 4,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Toma una foto clara del animal ya asegurado en el vehículo o al llegar a las instalaciones correspondientes.',
                      ),
                      const SizedBox(height: 12),
                      if (stepperState.evidenciaPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(stepperState.evidenciaPath!),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _tomarFotoEvidencia,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          stepperState.evidenciaPath != null
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
                  isActive: stepperState.currentStep >= 5,
                  content: DropdownButtonFormField<String>(
                    isExpanded: true, // PREVIENE EL OVERFLOW DE TEXTO LARGO
                    key: ValueKey(stepperState.destino),
                    value: stepperState.destino,
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Step(
                  title: const Text('7. Costo Operativo'),
                  subtitle: const Text('Gastos generados (MXN)'),
                  isActive: stepperState.currentStep >= 6,
                  content: Column(
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costoController,
                        focusNode: _costoFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Costo Total (MXN)',
                          helperText:
                              'Gastos médicos, gasolina o cuotas del refugio.',
                          prefixIcon: Icon(Icons.attach_money),
                          hintText: '\$ 0.00',
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(
                              r'[0-9.,\$ ]',
                            ), // Permite caracteres de moneda
                          ),
                        ],
                        onChanged: (v) => notifier.updateField(cost: v),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('8. Conclusión Final'),
                  subtitle: const Text('Resumen del caso'),
                  isActive: stepperState.currentStep >= 7,
                  content: Column(
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class WidgetRefBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  const WidgetRefBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context);
}
