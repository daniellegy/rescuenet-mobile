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
  });

  // Getter centralizado para el color UI basado en la urgencia
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

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      especie: json['especie'] ?? 'Desconocida',
      colorDominante: json['color_dominante'] ?? 'Desconocido',
      sexo: json['sexo'] ?? 'Desconocido',
      edadAprox: json['edad_aprox'] ?? 'Desconocida',
      tamano: json['tamano'] ?? 'No especificado',
      agresividad: int.tryParse(json['agresividad'].toString()) ?? 1,
      razaAprox: json['raza_aprox'] ?? 'Desconocida',
      caracteristicasEspeciales:
          json['caracteristicas_especiales'] ?? 'Ninguna',
      notasAdicionales: json['notas_adicionales'] ?? 'Sin notas',
      urgencia: json['urgencia'] ?? 'media', // Valor seguro
      estado: json['estado'] ?? 'Nuevo',
      latitud: double.tryParse(json['latitud'].toString()) ?? 0.0,
      longitud: double.tryParse(json['longitud'].toString()) ?? 0.0,
      fotoUrl: json['foto_url'],
    );
  }
}
