import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/app_exception.dart';

class ReportRepository {
  final Dio _dio;

  ReportRepository(this._dio);

  Future<void> createReport({
    required double lat,
    required double lng,
    required String especie,
    required String color,
    required String sexo,
    required String edadAprox,
    required String tamano,
    required int agresividad,
    required String razaAprox,
    required String caracteristicasEspeciales,
    required String notasAdicionales,
    required String urgencia,
    required String imagePath,
    int? radio,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'latitud': lat.toString(),
        'longitud': lng.toString(),
        'especie': especie,
        'color_dominante': color,
        'sexo': sexo,
        'edad_aprox': edadAprox,
        'tamano': tamano,
        'agresividad': agresividad,
        'raza_aprox': razaAprox,
        'caracteristicas_especiales': caracteristicasEspeciales,
        'notas_adicionales': notasAdicionales,
        'urgencia': urgencia,
        'radio': (radio ?? 500).toString(),
        'foto': await MultipartFile.fromFile(
          imagePath,
          filename: 'reporte.jpg',
        ),
      });

      await _dio.post('/reportes', data: formData);
    } on DioException catch (e) {
      throw AppException(
        e.response?.data['error'] ?? 'Error al enviar el reporte',
      );
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al enviar el reporte');
    }
  }

  Future<void> acceptReport(int id) async {
    try {
      await _dio.put('/reportes/$id/aceptar');
    } on DioException catch (e) {
      throw AppException(
        e.response?.data['error'] ?? 'Error al aceptar el rescate',
      );
    } catch (e) {
      throw AppException('Ocurrió un error inesperado');
    }
  }

  // NUEVO: Método para abortar rescate
  Future<void> abortReport(int id) async {
    try {
      await _dio.put('/reportes/$id/abortar');
    } on DioException catch (e) {
      throw AppException(
        e.response?.data['error'] ?? 'Error al abortar el rescate',
      );
    } catch (e) {
      throw AppException('Ocurrió un error inesperado');
    }
  }

  Future<void> updateProgress(
    int id, {
    bool? animalAvistado,
    String? lugarTraslado,
  }) async {
    try {
      await _dio.put(
        '/reportes/$id/progreso',
        data: {
          if (animalAvistado != null) 'animal_avistado': animalAvistado,
          if (lugarTraslado != null) 'lugar_traslado': lugarTraslado,
        },
      );
    } on DioException catch (e) {
      throw AppException(
        e.response?.data['error'] ?? 'Error al guardar progreso',
      );
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al guardar progreso');
    }
  }

  Future<void> finalizeReport(
    int id,
    Map<String, dynamic> detalles,
    String? evidenciaPath,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'condicion': detalles['condicion'],
        'destino': detalles['destino'],
        'costo': detalles['costo'].toString(),
        'conclusion': detalles['conclusion'],
        if (evidenciaPath != null)
          'evidencia': await MultipartFile.fromFile(
            evidenciaPath,
            filename: 'evidencia.jpg',
          ),
      });
      await _dio.put('/reportes/$id/finalizar', data: formData);
    } on DioException catch (e) {
      throw AppException(
        e.response?.data['error'] ?? 'Error al finalizar el rescate',
      );
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al finalizar');
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioClient = ref.watch(dioProvider);
  return ReportRepository(dioClient.instance);
});
