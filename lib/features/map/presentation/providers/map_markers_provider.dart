import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../history/domain/models/report_model.dart';
import '../../../settings/presentation/providers/map_limit_provider.dart';
import 'package:flutter/foundation.dart';

final reportesActivosMapaProvider = FutureProvider.autoDispose<List<ReportModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider).instance;
  final limit = ref.watch(mapLimitProvider);

  double? lat;
  double? lng;

  try {
    final locationService = ref.read(locationServiceProvider);
    // Solicitamos la coordenada silenciosamente. Ahora resolverá en milisegundos gracias al caché
    final position = await locationService.getCurrentPosition(
      requestPermission: false,
    );
    lat = position.latitude;
    lng = position.longitude;
  } catch (_) {
    // Falla silenciosa y limpia, el backend resolverá con la 'ultima_ubicacion' guardada
  }

  String url = '/reportes/activos?limit=$limit';

  if (lat != null && lng != null) {
    url += '&lat=$lat&lng=$lng';
  }

  final response = await dio.get(url);

  if (response.statusCode == 200) {
    List<dynamic> data = response.data is List
        ? response.data
        : (response.data['data'] ?? []);

    List<ReportModel> reportesValidos = [];

    for (var jsonItem in data) {
      try {
        final reporte = ReportModel.fromJson(jsonItem);
        // Evitamos puntos nulos o de desbordamiento en memoria
        if (!reporte.latitud.isNaN &&
            !reporte.longitud.isNaN &&
            reporte.latitud >= -90.0 &&
            reporte.latitud <= 90.0 &&
            reporte.longitud >= -180.0 &&
            reporte.longitud <= 180.0) {
          reportesValidos.add(reporte);
        }
      } catch (e) {
        debugPrint('Error de parseo en un reporte: $e');
      }
    }
    return reportesValidos;
  } else {
    throw Exception('Error al cargar reportes del mapa');
  }
});
