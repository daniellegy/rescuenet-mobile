import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../domain/models/report_model.dart';

class HistoryRepository {
  final Dio _dio;

  HistoryRepository(this._dio);

  Future<List<ReportModel>> getMyReports() async {
    try {
      final response = await _dio.get('/reportes/mis-reportes');
      final data = response.data as List;
      return data.map((json) => ReportModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Error inesperado al cargar el historial de reportes');
    }
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final dioClient = ref.watch(dioProvider);
  return HistoryRepository(dioClient.instance);
});
