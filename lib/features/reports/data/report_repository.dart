import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class ReportRepository {
  final Dio _dio;

  ReportRepository(this._dio);

  Future<void> createReport({
    required double lat,
    required double lng,
    required String especie,
    required String color,
    required String imagePath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'latitud': lat.toString(),
        'longitud': lng.toString(),
        'especie': especie,
        'color_dominante': color,
        'foto': await MultipartFile.fromFile(
          imagePath,
          filename: 'reporte.jpg',
        ),
      });

      await _dio.post('/reportes', data: formData);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Error al enviar el reporte',
      );
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioClient = ref.watch(dioProvider);
  return ReportRepository(dioClient.instance);
});
