import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../history/domain/models/report_model.dart';

class OffScreenMarkers extends StatelessWidget {
  final MapController mapController;
  final List<ReportModel> reportes;
  final double topMargin; // NUEVA PROPIEDAD DINÁMICA

  const OffScreenMarkers({
    super.key,
    required this.mapController,
    required this.reportes,
    this.topMargin = 24.0, // Valor por defecto
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return StreamBuilder<MapEvent>(
          stream: mapController.mapEventStream,
          builder: (context, snapshot) {
            // Aseguramos que la cámara está montada y lista
            if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
              return const SizedBox.shrink();
            }
            final camera = mapController.camera;
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final center = Offset(width / 2, height / 2);

            // USO DEL MARGEN DINÁMICO
            final sideMargin = 24.0;
            final bottomMargin = 130.0;

            final minX = sideMargin;
            final maxX = width - sideMargin;
            final minY =
                topMargin; // Ahora se rige por el parámetro del constructor
            final maxY = height - bottomMargin;

            return Stack(
              fit: StackFit.expand,
              children: reportes.map((reporte) {
                final pos = LatLng(reporte.latitud, reporte.longitud);
                if (camera.visibleBounds.contains(pos)) {
                  return const SizedBox.shrink(); // No dibujamos si está en pantalla
                }

                final lat1 = camera.center.latitude * math.pi / 180;
                final lng1 = camera.center.longitude * math.pi / 180;
                final lat2 = pos.latitude * math.pi / 180;
                final lng2 = pos.longitude * math.pi / 180;

                final dLng = lng2 - lng1;
                final y = math.sin(dLng) * math.cos(lat2);
                final x =
                    math.cos(lat1) * math.sin(lat2) -
                    math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
                final bearing = math.atan2(y, x);

                final dx = math.sin(bearing);
                final dy = -math.cos(bearing);

                if (dx.abs() < 0.0001 && dy.abs() < 0.0001) {
                  return const SizedBox.shrink();
                }

                double t = double.infinity;
                if (dx.abs() > 0.0001) {
                  if (dx > 0) {
                    t = math.min(t, (maxX - center.dx) / dx);
                  }
                  if (dx < 0) {
                    t = math.min(t, (minX - center.dx) / dx);
                  }
                }
                if (dy.abs() > 0.0001) {
                  if (dy > 0) {
                    t = math.min(t, (maxY - center.dy) / dy);
                  }
                  if (dy < 0) {
                    t = math.min(t, (minY - center.dy) / dy);
                  }
                }

                if (t == double.infinity || t.isNaN) {
                  return const SizedBox.shrink();
                }

                final indicatorX = center.dx + t * dx;
                final indicatorY = center.dy + t * dy;

                if (indicatorX.isNaN || indicatorY.isNaN) {
                  return const SizedBox.shrink();
                }

                final bool estaEnProceso =
                    reporte.estado.toString().trim().toUpperCase() ==
                    'EN_PROCESO';

                return Positioned(
                  left: indicatorX - 18,
                  top: indicatorY - 18,
                  child: Transform.rotate(
                    angle: bearing,
                    child: GestureDetector(
                      onTap: () {
                        mapController.move(pos, 17);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: reporte.colorUrgencia,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: reporte.colorUrgencia.withValues(
                                alpha: 0.6,
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          estaEnProceso
                              ? Icons.hourglass_top_rounded
                              : Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
