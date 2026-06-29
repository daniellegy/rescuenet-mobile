import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/dio_client.dart';
import '../../../history/domain/models/report_model.dart';
import 'package:flutter/foundation.dart';

final reportesActivosMapaProvider = FutureProvider.autoDispose<List<ReportModel>>(
  (ref) async {
    final dio = ref.watch(dioProvider).instance;

    double? lat;
    double? lng;

    try {
      // Solicitamos silenciosamente la coordenada como en ActiveReportsProvider
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (_) {
      // Falla limpia, el backend resolverá con la 'ultima_ubicacion' guardada
    }

    String url = '/reportes/activos';

    if (lat != null && lng != null) {
      url += '?lat=$lat&lng=$lng';
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
  },
);
