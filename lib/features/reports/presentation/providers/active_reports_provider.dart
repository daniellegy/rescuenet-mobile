import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../history/domain/models/report_model.dart';

final activeReportsProvider = FutureProvider.autoDispose<List<ReportModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider).instance;
  final response = await dio.get('/reportes/activos');

  final List<dynamic> data = response.data;
  return data.map((json) => ReportModel.fromJson(json)).toList();
});
