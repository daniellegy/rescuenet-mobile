import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../history/domain/models/report_model.dart';

final activeReportsProvider = FutureProvider.autoDispose<List<ReportModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider).instance;

  double? lat;
  double? lng;

  try {
    // Si la app tiene permiso, captura la coordenada silenciosamente para el filtro de rescates
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // CORRECCIÓN: Uso de LocationSettings en lugar de desiredAccuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    }
  } catch (_) {
    // Si el GPS está apagado, se usará la "última ubicación" conocida por el backend
  }

  String url = '/reportes/activos';

  if (lat != null && lng != null) {
    url += '?lat=$lat&lng=$lng';
  }

  final response = await dio.get(url);

  final List<dynamic> data = response.data;
  return data.map((json) => ReportModel.fromJson(json)).toList();
});
