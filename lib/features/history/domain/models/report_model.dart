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
  final double latitud;
  final double longitud;
  final String? fotoUrl;
  final String? fotoEvidenciaUrl;
  final DateTime? fechaCreacion;
  final int? usuarioReportadorId;
  final int? usuarioRescatistaId;
  final String? nombreReportador;
  final String? nombreRescatista;
  final bool? animalAvistado;
  final String? lugarTraslado;
  final String? destinoFinal;
  final String? condicionRescate;
  final double? costoRescate;
  final int? radio;
  final String? referencias;

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
    required this.latitud,
    required this.longitud,
    this.fotoUrl,
    this.fotoEvidenciaUrl,
    this.fechaCreacion,
    this.usuarioReportadorId,
    this.usuarioRescatistaId,
    this.nombreReportador,
    this.nombreRescatista,
    this.animalAvistado,
    this.lugarTraslado,
    this.destinoFinal,
    this.condicionRescate,
    this.costoRescate,
    this.radio,
    this.referencias,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      especie: json['especie'] ?? 'Desconocida',
      colorDominante: json['color_dominante'] ?? 'Desconocido',
      sexo: json['sexo'] ?? 'Desconocido',
      edadAprox: json['edad_aprox'] ?? 'Desconocida',
      tamano: json['tamano'] ?? 'Desconocido',
      agresividad: json['agresividad'] ?? 1,
      razaAprox: json['raza_aprox'] ?? 'Desconocida',
      caracteristicasEspeciales:
          json['caracteristicas_especiales'] ?? 'Ninguna',
      notasAdicionales: json['notas_adicionales'] ?? 'Ninguna',
      urgencia: json['urgencia'] ?? 'media',
      estado: json['estado'] ?? 'Nuevo',
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      fotoUrl: json['foto_url'],
      fotoEvidenciaUrl: json['foto_evidencia_url'],
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
      usuarioReportadorId: json['usuario_reportador_id'],
      usuarioRescatistaId: json['usuario_rescatista_id'],
      nombreReportador: json['nombre_reportador'],
      nombreRescatista: json['nombre_rescatista'],
      animalAvistado: json['animal_avistado'],
      lugarTraslado: json['lugar_traslado'],
      destinoFinal: json['destino_final'],
      condicionRescate: json['condicion_rescate'],
      costoRescate: json['costo_rescate'] != null
          ? double.tryParse(json['costo_rescate'].toString())
          : null,
      radio: json['radio'],
      referencias: json['referencias'] ?? 'Sin referencias',
    );
  }

  String get estadoFormateado => estado.replaceAll('_', ' ');

  Color get colorUrgencia {
    switch (urgencia.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  int get pesoUrgencia {
    switch (urgencia.toLowerCase()) {
      case 'alta':
        return 3;
      case 'media':
        return 2;
      case 'baja':
        return 1;
      default:
        return 0;
    }
  }

  String get tiempoTranscurrido {
    if (fechaCreacion == null) return 'hace un momento';
    final diferencia = DateTime.now().difference(fechaCreacion!);
    if (diferencia.inDays > 0) return 'hace ${diferencia.inDays} d';
    if (diferencia.inHours > 0) return 'hace ${diferencia.inHours} h';
    if (diferencia.inMinutes > 0) return 'hace ${diferencia.inMinutes} min';
    return 'hace un momento';
  }
}
