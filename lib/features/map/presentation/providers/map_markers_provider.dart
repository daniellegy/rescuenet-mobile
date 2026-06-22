import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../history/domain/models/report_model.dart';
import 'package:flutter/foundation.dart';

final reportesActivosMapaProvider = FutureProvider.autoDispose<List<ReportModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider).instance;
  final response = await dio.get('/reportes/activos');

  if (response.statusCode == 200) {
    List<dynamic> data = response.data is List
        ? response.data
        : (response.data['data'] ?? []);

    List<ReportModel> reportesValidos = [];

    for (var jsonItem in data) {
      try {
        final reporte = ReportModel.fromJson(jsonItem);
        // Filtrado geográfico y matemático estricto a nivel de lógica de negocio, no de UI
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
