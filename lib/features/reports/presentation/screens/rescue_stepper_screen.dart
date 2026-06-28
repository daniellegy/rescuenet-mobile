import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../history/domain/models/report_model.dart';
import '../../data/report_repository.dart';
import '../providers/active_reports_provider.dart';
import '../providers/my_active_rescue_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../providers/rescue_stepper_provider.dart';
import '../../../../core/services/camera_service.dart';

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
  }

  @override
  void dispose() {
    _costoController.dispose();
    _conclusionController.dispose();
    super.dispose();
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
      final detalles = {
        'condicion': estado.condicion ?? 'Desconocida',
        'destino': estado.destino,
        'costo': double.tryParse(_costoController.text) ?? 0.0,
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
      appBar: AppBar(title: const Text('Asistente de Rescate')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              physics: const ClampingScrollPhysics(),
              currentStep: stepperState.currentStep,
              onStepContinue: () async {
                if (stepperState.currentStep == 0) {
                  if (stepperState.animalPresente == null) {
                    return;
                  }
                  if (stepperState.animalPresente == 'No') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Seleccionaste que no está. Puedes abortar el rescate.',
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
                  } catch (_) {}
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
                  isActive: stepperState.currentStep >= 0,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('¿Llegaste a la ubicación? ¿Está el animal?'),
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
                            'Prepárate con guantes, correa, transportadora y manta.',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('2. Condiciones'),
                  isActive: stepperState.currentStep >= 1,
                  content: DropdownButtonFormField<String>(
                    key: ValueKey(stepperState.condicion),
                    initialValue: stepperState.condicion,
                    items: ['Accesible', 'Atrapado / Encerrado', 'Herido']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => notifier.updateField(cond: v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Step(
                  title: const Text('3. Acción y Protocolo'),
                  isActive: stepperState.currentStep >= 2,
                  content: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      stepperState.condicion == 'Herido'
                          ? 'Manejo crítico: Usa guantes gruesos y manta.'
                          : stepperState.condicion == 'Atrapado / Encerrado'
                          ? 'Si requiere romper rejas, solicita apoyo. Si es seguro, usa correa.'
                          : 'Acércate despacio usando comida.',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                Step(
                  title: const Text('4. Traslado (Directorio)'),
                  isActive: stepperState.currentStep >= 3,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('¿A dónde llevarás al animal?'),
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
                        Builder(
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
                              key: ValueKey(valorSeguro),
                              initialValue: valorSeguro,
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
                          label: const Text('Confirmar y Navegar'),
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
                  isActive: stepperState.currentStep >= 4,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Toma una foto del animal ya asegurado o en camino.',
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
                              ? 'Cambiar Foto'
                              : 'Tomar Foto',
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('6. Seguimiento'),
                  isActive: stepperState.currentStep >= 5,
                  content: DropdownButtonFormField<String>(
                    key: ValueKey(stepperState.destino),
                    initialValue: stepperState.destino,
                    hint: const Text('¿Dónde ubicaste al animal?'),
                    items:
                        [
                              'Veterinaria',
                              'Albergue / Refugio',
                              'Retención Temporal (Mi casa)',
                              'Se escapó en el traslado',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) => notifier.updateField(dest: v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Step(
                  title: const Text('7. Costo Operativo'),
                  isActive: stepperState.currentStep >= 6,
                  content: Column(
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Costo Total (MXN)',
                          helperText: 'Gastos de clínica o cuotas del refugio.',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => notifier.updateField(cost: v),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('8. Conclusión Final'),
                  isActive: stepperState.currentStep >= 7,
                  content: TextFormField(
                    controller: _conclusionController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Estado final del animal',
                      hintText: 'Ej. Está estable internado en la clínica.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => notifier.updateField(concl: v),
                  ),
                ),
              ],
            ),
    );
  }
}
