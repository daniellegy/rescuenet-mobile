import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/report_model.dart';

final miRescateActivoProvider = FutureProvider.autoDispose<ReportModel?>((
  ref,
) async {
  final dio = ref.watch(dioProvider).instance;
  final response = await dio.get('/reportes/mi-rescate');

  // Si el servidor devuelve un string vacío o nulo (no hay rescate)
  if (response.data == null || response.data.toString().isEmpty) {
    return null;
  }

  return ReportModel.fromJson(response.data);
});
