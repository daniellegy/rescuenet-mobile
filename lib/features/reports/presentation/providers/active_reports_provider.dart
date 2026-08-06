import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../history/domain/models/report_model.dart';
import '../../../settings/presentation/providers/map_limit_provider.dart';

final activeReportsProvider = FutureProvider.autoDispose<List<ReportModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider).instance;
  final limit = ref.watch(mapLimitProvider);

  double? lat;
  double? lng;

  try {
    final locationService = ref.read(locationServiceProvider);
    // Uso del servicio optimizado para reflejar la recarga al instante
    final position = await locationService.getCurrentPosition(
      requestPermission: false,
    );
    lat = position.latitude;
    lng = position.longitude;
  } catch (_) {
    // Falla silenciosa, si no hay GPS se enviará al backend nulo y usará la última conocida en DB
  }

  String url = '/reportes/activos?limit=$limit';
  if (lat != null && lng != null) {
    url += '&lat=$lat&lng=$lng';
  }

  final response = await dio.get(url);
  final List<dynamic> data = response.data;

  return data.map((json) => ReportModel.fromJson(json)).toList();
});
