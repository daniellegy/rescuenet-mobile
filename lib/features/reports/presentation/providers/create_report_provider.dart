import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/report_repository.dart';

class CreateReportState {
  final String? especie;
  final String? razaSeleccionada;
  final String urgenciaSeleccionada;
  final int radioSeleccionado;
  final String? colorSeleccionado;
  final String sexo;
  final String edad;
  final String tamano;
  final double agresividad;
  final bool isLoading;
  final bool activarCanal;
  final double lat;
  final double lng;

  CreateReportState({
    this.especie,
    this.razaSeleccionada,
    this.urgenciaSeleccionada = 'media',
    this.radioSeleccionado = 500,
    this.colorSeleccionado,
    this.sexo = 'Desconocido',
    this.edad = 'Cachorro',
    this.tamano = 'Pequeño',
    this.agresividad = 0.0,
    this.isLoading = false,
    this.activarCanal = false,
    required this.lat,
    required this.lng,
  });

  CreateReportState copyWith({
    String? especie,
    String? razaSeleccionada,
    String? urgenciaSeleccionada,
    int? radioSeleccionado,
    String? colorSeleccionado,
    String? sexo,
    String? edad,
    String? tamano,
    double? agresividad,
    bool? isLoading,
    bool? activarCanal,
    double? lat,
    double? lng,
    bool clearRaza = false,
  }) {
    return CreateReportState(
      especie: especie ?? this.especie,
      razaSeleccionada: clearRaza
          ? null
          : (razaSeleccionada ?? this.razaSeleccionada),
      urgenciaSeleccionada: urgenciaSeleccionada ?? this.urgenciaSeleccionada,
      radioSeleccionado: radioSeleccionado ?? this.radioSeleccionado,
      colorSeleccionado: colorSeleccionado ?? this.colorSeleccionado,
      sexo: sexo ?? this.sexo,
      edad: edad ?? this.edad,
      tamano: tamano ?? this.tamano,
      agresividad: agresividad ?? this.agresividad,
      isLoading: isLoading ?? this.isLoading,
      activarCanal: activarCanal ?? this.activarCanal,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class CreateReportNotifier extends Notifier<CreateReportState> {
  @override
  CreateReportState build() {
    return CreateReportState(lat: 0.0, lng: 0.0);
  }

  void toggleActivarCanal(bool value) {
    state = state.copyWith(activarCanal: value);
  }

  void setInitialLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng);
  }

  void updateLocation(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng);
  }

  void updateField({
    String? especie,
    String? raza,
    String? urgencia,
    int? radio,
    String? color,
    String? sexo,
    String? edad,
    String? tamano,
    double? agresividad,
  }) {
    state = state.copyWith(
      especie: especie,
      razaSeleccionada: raza,
      clearRaza: especie != null && especie != state.especie,
      urgenciaSeleccionada: urgencia,
      radioSeleccionado: radio,
      colorSeleccionado: color,
      sexo: sexo,
      edad: edad,
      tamano: tamano,
      agresividad: agresividad,
    );
  }

  void reset() {
    state = CreateReportState(lat: 0.0, lng: 0.0);
  }

  Future<void> submitReport({
    required String imagePath,
    required String caracteristicas,
    required String referencias,
    String? razaPersonalizada,
  }) async {
    if (state.especie == null ||
        state.razaSeleccionada == null ||
        state.colorSeleccionado == null) {
      throw Exception(
        'Por favor completa todos los selectores principales (Especie, Raza, Color).',
      );
    }

    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(reportRepositoryProvider);

      // Si es otro y escribieron algo guardamos el texto manual
      final razaFinal =
          (state.razaSeleccionada == 'Otro' &&
              razaPersonalizada != null &&
              razaPersonalizada.trim().isNotEmpty)
          ? razaPersonalizada.trim()
          : state.razaSeleccionada!;

      await repository.createReport(
        lat: state.lat,
        lng: state.lng,
        especie: state.especie!,
        color: state.colorSeleccionado!,
        sexo: state.sexo,
        edadAprox: state.edad,
        tamano: state.tamano,
        agresividad: state.agresividad.toInt(),
        razaAprox: razaFinal,
        caracteristicasEspeciales: caracteristicas,
        notasAdicionales: '',
        urgencia: state.urgenciaSeleccionada,
        imagePath: imagePath,
        referencias: referencias,
        radio: state.radioSeleccionado,
        activarCanal: state.activarCanal,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final createReportProvider =
    NotifierProvider<CreateReportNotifier, CreateReportState>(
      () => CreateReportNotifier(),
    );
