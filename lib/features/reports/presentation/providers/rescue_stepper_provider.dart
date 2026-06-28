import 'package:flutter_riverpod/flutter_riverpod.dart';

class RescueStepperState {
  final int currentStep;
  final String? animalPresente;
  final String? condicion;
  final String? tipoTraslado;
  final String? lugarTraslado;
  final String? evidenciaPath;
  final String? destino;
  final String costo;
  final String conclusion;

  RescueStepperState({
    this.currentStep = 0,
    this.animalPresente,
    this.condicion,
    this.tipoTraslado,
    this.lugarTraslado,
    this.evidenciaPath,
    this.destino,
    this.costo = '0',
    this.conclusion = '',
  });

  RescueStepperState copyWith({
    int? currentStep,
    String? animalPresente,
    String? condicion,
    String? tipoTraslado,
    String? lugarTraslado,
    String? evidenciaPath,
    String? destino,
    String? costo,
    String? conclusion,
  }) {
    return RescueStepperState(
      currentStep: currentStep ?? this.currentStep,
      animalPresente: animalPresente ?? this.animalPresente,
      condicion: condicion ?? this.condicion,
      tipoTraslado: tipoTraslado ?? this.tipoTraslado,
      lugarTraslado: lugarTraslado ?? this.lugarTraslado,
      evidenciaPath: evidenciaPath ?? this.evidenciaPath,
      destino: destino ?? this.destino,
      costo: costo ?? this.costo,
      conclusion: conclusion ?? this.conclusion,
    );
  }
}

class RescueStepperNotifier extends Notifier<RescueStepperState> {
  @override
  RescueStepperState build() {
    return RescueStepperState();
  }

  void updateField({
    int? step,
    String? animal,
    String? cond,
    String? tipoTras,
    String? lugarTras,
    String? evidencia,
    String? dest,
    String? cost,
    String? concl,
  }) {
    state = state.copyWith(
      currentStep: step,
      animalPresente: animal,
      condicion: cond,
      tipoTraslado: tipoTras,
      lugarTraslado: lugarTras,
      evidenciaPath: evidencia,
      destino: dest,
      costo: cost,
      conclusion: concl,
    );
  }

  // NUEVO: Función exclusiva para limpiar el lugar y evitar el crasheo del Dropdown
  void clearLugarTraslado() {
    state = RescueStepperState(
      currentStep: state.currentStep,
      animalPresente: state.animalPresente,
      condicion: state.condicion,
      tipoTraslado: state.tipoTraslado,
      lugarTraslado: null, // Forzamos el borrado explícito
      evidenciaPath: state.evidenciaPath,
      destino: state.destino,
      costo: state.costo,
      conclusion: state.conclusion,
    );
  }

  void reset() {
    state = RescueStepperState();
  }
}

final rescueStepperProvider =
    NotifierProvider<RescueStepperNotifier, RescueStepperState>(
      () => RescueStepperNotifier(),
    );
