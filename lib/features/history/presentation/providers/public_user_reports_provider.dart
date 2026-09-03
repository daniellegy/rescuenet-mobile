import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../reports/domain/models/report_model.dart';

final publicUserReportsProvider = FutureProvider.autoDispose
    .family<List<ReportModel>, int>((ref, userId) async {
      final dio = ref.watch(dioProvider).instance;

      // Endpoint que debes tener en tu backend de Railway para traer el historial de un usuario
      final response = await dio.get('/reportes/usuario/$userId');

      final List<dynamic> data = response.data;
      return data.map((json) => ReportModel.fromJson(json)).toList();
    });
