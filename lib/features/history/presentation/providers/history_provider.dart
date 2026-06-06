import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

final misReportesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final dio = ref.watch(dioProvider).instance;
    final response = await dio.get('/reportes/mis-reportes');

    final data = response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }

    return const [];
  },
);