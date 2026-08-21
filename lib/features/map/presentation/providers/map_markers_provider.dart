import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

import '../../../../core/network/dio_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../history/domain/models/report_model.dart';
import '../../../settings/presentation/providers/map_limit_provider.dart';

class MapExplorationCenterNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() {
    return null; // Estado inicial
  }
  void updatePosition(LatLng? newPosition) {
    state = newPosition;
  }
}
final mapExplorationCenterProvider = NotifierProvider<MapExplorationCenterNotifier, LatLng?>(() {
  return MapExplorationCenterNotifier();
});

final reportesActivosMapaProvider = FutureProvider.autoDispose<List<ReportModel>>((ref) async {
  final dio = ref.watch(dioProvider).instance;
  final limit = ref.watch(mapLimitProvider);

  final explorePos = ref.watch(mapExplorationCenterProvider);
  double? lat;
  double? lng;

  if (explorePos != null) {
   
    lat = explorePos.latitude;
    lng = explorePos.longitude;
  } else {
    
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition(requestPermission: false);
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}
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