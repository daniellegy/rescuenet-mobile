class ReportModel {
  final int id;
  final String especie;
  final String colorDominante;
  final String sexo;
  final String edadAprox;
  final String tamano;
  final String razaAprox;
  final String caracteristicasEspeciales;
  final String notasAdicionales;
  final double latitud;
  final double longitud;
  final String? fotoUrl;

  ReportModel({
    required this.id,
    required this.especie,
    required this.colorDominante,
    required this.sexo,
    required this.edadAprox,
    required this.tamano,
    required this.razaAprox,
    required this.caracteristicasEspeciales,
    required this.notasAdicionales,
    required this.latitud,
    required this.longitud,
    this.fotoUrl,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      especie: json['especie'] ?? 'Desconocida',
      colorDominante: json['color_dominante'] ?? 'Desconocido',
      sexo: json['sexo'] ?? 'Desconocido',
      edadAprox: json['edad_aprox'] ?? 'Desconocida',
      tamano: json['tamano'] ?? 'No especificado',
      razaAprox: json['raza_aprox'] ?? 'Desconocida',
      caracteristicasEspeciales:
          json['caracteristicas_especiales'] ?? 'Ninguna',
      notasAdicionales: json['notas_adicionales'] ?? 'Sin notas',
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      fotoUrl: json['foto_url'],
    );
  }
}
