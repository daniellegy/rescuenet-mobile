import 'package:flutter/material.dart';

class ReportModel {
  final int id;
  final String especie;
  final String colorDominante;
  final String sexo;
  final String edadAprox;
  final String tamano;
  final int agresividad;
  final String razaAprox;
  final String caracteristicasEspeciales;
  final String notasAdicionales;
  final String urgencia;
  final String estado;
  final int? usuarioRescatistaId;
  final int usuarioReportadorId;
  final double latitud;
  final double longitud;
  final String? fotoUrl;
  final int? radio;

  final String? nombreReportador;
  final String? nombreRescatista;
  final DateTime? fechaCreacion;

  ReportModel({
    required this.id,
    required this.especie,
    required this.colorDominante,
    required this.sexo,
    required this.edadAprox,
    required this.tamano,
    required this.agresividad,
    required this.razaAprox,
    required this.caracteristicasEspeciales,
    required this.notasAdicionales,
    required this.urgencia,
    required this.estado,
    this.usuarioRescatistaId,
    required this.usuarioReportadorId,
    required this.latitud,
    required this.longitud,
    this.fotoUrl,
    this.radio,
    this.nombreReportador,
    this.nombreRescatista,
    this.fechaCreacion,
  });

  Color get colorUrgencia {
    switch (urgencia.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.amber;
      default:
        return Colors.orange;
    }
  }

  String get tiempoTranscurrido {
    if (fechaCreacion == null) return 'hace un momento';
    final ahora = DateTime.now();
    Duration diferencia = ahora.difference(fechaCreacion!);
    if (diferencia.isNegative) {
      diferencia = diferencia.abs();
    }

    if (diferencia.inDays > 1) return 'hace ${diferencia.inDays} días';
    if (diferencia.inDays == 1) return 'hace 1 día';
    if (diferencia.inHours >= 1) return 'hace ${diferencia.inHours} hrs';
    if (diferencia.inMinutes >= 1) return 'hace ${diferencia.inMinutes} min';

    return 'hace un momento';
  }

  String get estadoFormateado {
    return estado.replaceAll('_', ' ');
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as int? ?? 0,
      especie: json['especie']?.toString() ?? 'Desconocida',
      colorDominante: json['color_dominante']?.toString() ?? 'Desconocido',
      sexo: json['sexo']?.toString() ?? 'Desconocido',
      edadAprox: json['edad_aprox']?.toString() ?? 'Desconocida',
      tamano: json['tamano']?.toString() ?? 'No especificado',
      agresividad: int.tryParse(json['agresividad']?.toString() ?? '1') ?? 1,
      razaAprox: json['raza_aprox']?.toString() ?? 'Desconocida',
      caracteristicasEspeciales:
          json['caracteristicas_especiales']?.toString() ?? 'Ninguna',
      notasAdicionales: json['notas_adicionales']?.toString() ?? 'Sin notas',
      urgencia: json['urgencia']?.toString() ?? 'media',
      estado: json['estado']?.toString() ?? 'Nuevo',
      usuarioRescatistaId: json['usuario_rescatista_id'] != null
          ? int.tryParse(json['usuario_rescatista_id'].toString())
          : null,
      usuarioReportadorId:
          int.tryParse(json['usuario_reportador_id']?.toString() ?? '0') ?? 0,
      latitud: double.tryParse(json['latitud']?.toString() ?? '0.0') ?? 0.0,
      longitud: double.tryParse(json['longitud']?.toString() ?? '0.0') ?? 0.0,
      fotoUrl: json['foto_url']?.toString(),
      radio: json['radio'] != null ? json['radio'] as int : null,
      // MAPEAMOS LOS NOMBRES
      nombreReportador: json['nombre_reportador']?.toString(),
      nombreRescatista: json['nombre_rescatista']?.toString(),
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : json['creado_el'] != null
          ? DateTime.tryParse(json['creado_el'].toString())
          : null,
    );
  }
}
