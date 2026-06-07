import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/history_repository.dart';
import '../../domain/models/report_model.dart';

final misReportesProvider = FutureProvider.autoDispose<List<ReportModel>>((
  ref,
) async {
  final repository = ref.watch(historyRepositoryProvider);
  return await repository.getMyReports();
});
