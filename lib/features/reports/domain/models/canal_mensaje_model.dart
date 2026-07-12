class CanalMensajeModel {
  final int id;
  final int reporteId;
  final int autorId;
  final String contenido;
  final DateTime creadoEl;
  final String? nombreAutor;

  CanalMensajeModel({
    required this.id,
    required this.reporteId,
    required this.autorId,
    required this.contenido,
    required this.creadoEl,
    this.nombreAutor,
  });

  factory CanalMensajeModel.fromJson(Map<String, dynamic> json) {
    return CanalMensajeModel(
      id: json['id'],
      reporteId: json['reporte_id'],
      autorId: json['autor_id'],
      contenido: json['contenido'] ?? '',
      creadoEl: json['creado_el'] != null
          ? DateTime.parse(json['creado_el'])
          : DateTime.now(),
      nombreAutor: json['nombre_autor'],
    );
  }

  String get horaFormateada {
    final hora = creadoEl.hour.toString().padLeft(2, '0');
    final minuto = creadoEl.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}