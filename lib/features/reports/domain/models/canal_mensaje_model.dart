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
    // Pasamos a la hora local del dispositivo
    DateTime parsearFechaLocal(String? fechaStr) {
      if (fechaStr == null) return DateTime.now();
      String fechaCorregida = fechaStr;

      if (!fechaCorregida.endsWith('Z')) {
        fechaCorregida += 'Z';
      }

      // toLocal() automáticamente calculará el desfase correcto
      return DateTime.parse(fechaCorregida).toLocal();
    }

    return CanalMensajeModel(
      id: json['id'],
      reporteId: json['reporte_id'],
      autorId: json['autor_id'],
      contenido: json['contenido'] ?? '',
      creadoEl: parsearFechaLocal(json['creado_el']),
      nombreAutor: json['nombre_autor'],
    );
  }

  String get horaFormateada {
    // Formateo de am y pm
    int hora = creadoEl.hour;
    final minuto = creadoEl.minute.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'PM' : 'AM';

    if (hora > 12) {
      hora -= 12;
    } else if (hora == 0) {
      hora = 12;
    }

    final horaStr = hora.toString().padLeft(2, '0');
    return '$horaStr:$minuto $periodo';
  }
}
