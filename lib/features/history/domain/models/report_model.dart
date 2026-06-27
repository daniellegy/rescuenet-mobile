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
  final int? usuarioRescatistaId; // NUEVO: Determina si el caso es mío
  final double latitud;
  final double longitud;
  final String? fotoUrl;
  final int? radio;

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
    required this.latitud,
    required this.longitud,
    this.fotoUrl,
    this.radio,
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

  // NUEVO: Formateador visual para quitar el "En_Proceso" de la UI
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
      // Mapeo seguro del ID del rescatista
      usuarioRescatistaId: json['usuario_rescatista_id'] != null
          ? int.tryParse(json['usuario_rescatista_id'].toString())
          : null,
      latitud: double.tryParse(json['latitud']?.toString() ?? '0.0') ?? 0.0,
      longitud: double.tryParse(json['longitud']?.toString() ?? '0.0') ?? 0.0,
      fotoUrl: json['foto_url']?.toString(),
      radio: json['radio'] != null ? json['radio'] as int : null,
    );
  }
}
