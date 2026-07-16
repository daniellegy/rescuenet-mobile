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
    required String referencias,
    int? radio,
    bool activarCanal = false,
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
        'referencias': referencias,
        'radio': (radio ?? 500).toString(),
        'activarCanal': activarCanal.toString(),
        'foto': await MultipartFile.fromFile(
          imagePath,
          filename: 'reporte.jpg',
        ),
      });

      await _dio.post('/reportes', data: formData);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al enviar el reporte');
    }
  }

  Future<void> acceptReport(int id) async {
    try {
      await _dio.put('/reportes/$id/aceptar');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado');
    }
  }

  Future<void> abortReport(int id) async {
    try {
      await _dio.put('/reportes/$id/abortar');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
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
      throw AppException.fromDioException(e);
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
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al finalizar');
    }
  }

  Future<Map<String, dynamic>> obtenerEstadoCanal(int reporteId) async {
    try {
      final response = await _dio.get('/reportes/$reporteId/canal');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al obtener el canal');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerMensajesCanal(int reporteId) async {
    try {
      final response = await _dio.get('/reportes/$reporteId/canal/mensajes');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al obtener mensajes');
    }
  }

  Future<Map<String, dynamic>> enviarMensajeCanal(
    int reporteId,
    String contenido,
  ) async {
    try {
      final response = await _dio.post(
        '/reportes/$reporteId/canal/mensajes',
        data: {'contenido': contenido},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al enviar el mensaje');
    }
  }

  Future<void> activarCanalManual(int reporteId) async {
    try {
      await _dio.put('/reportes/$reporteId/canal/activar');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al activar el canal');
    }
  }

  Future<void> cerrarCanalManual(int reporteId) async {
    try {
      await _dio.put('/reportes/$reporteId/canal/cerrar');
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al cerrar el canal');
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioClient = ref.watch(dioProvider);
  return ReportRepository(dioClient.instance);
});
