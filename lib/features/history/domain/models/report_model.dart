class ReportModel {
  final int id;
  final String especie;
  final String colorDominante;
  final String referencias;
  final double latitud;
  final double longitud;
  final String? fotoUrl;

  ReportModel({
    required this.id,
    required this.especie,
    required this.colorDominante,
    required this.referencias,
    required this.latitud,
    required this.longitud,
    this.fotoUrl,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      especie: json['especie'] ?? 'Desconocida',
      colorDominante: json['color_dominante'] ?? 'Desconocido',
      referencias: json['referencias'] ?? 'Sin referencias',
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      fotoUrl: json['foto_url'],
    );
  }
}
