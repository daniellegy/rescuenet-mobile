import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../reports/domain/models/report_model.dart';

class OffScreenMarkers extends StatefulWidget {
  final GoogleMapController? mapController;
  final List<ReportModel> reportes;
  final ValueNotifier<CameraPosition?> cameraNotifier;
  final double topMargin;

  const OffScreenMarkers({
    super.key,
    required this.mapController,
    required this.reportes,
    required this.cameraNotifier,
    this.topMargin = 24.0,
  });

  @override
  State<OffScreenMarkers> createState() => _OffScreenMarkersState();
}

class _OffScreenMarkersState extends State<OffScreenMarkers> {
  LatLngBounds? _bounds;

  @override
  void initState() {
    super.initState();
    widget.cameraNotifier.addListener(_updateBounds);
    _updateBounds();
  }

  @override
  void didUpdateWidget(OffScreenMarkers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraNotifier != widget.cameraNotifier) {
      oldWidget.cameraNotifier.removeListener(_updateBounds);
      widget.cameraNotifier.addListener(_updateBounds);
    }
  }

  @override
  void dispose() {
    widget.cameraNotifier.removeListener(_updateBounds);
    super.dispose();
  }

  Future<void> _updateBounds() async {
    if (widget.mapController == null) {
      return;
    }
    try {
      final bounds = await widget.mapController!.getVisibleRegion();
      if (mounted) {
        setState(() {
          _bounds = bounds;
        });
      }
    } catch (e) {
      // Ignorar errores de movimiento rápido de la cámara
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<CameraPosition?>(
          valueListenable: widget.cameraNotifier,
          builder: (context, camera, _) {
            if (camera == null ||
                widget.mapController == null ||
                _bounds == null) {
              return const SizedBox.shrink();
            }

            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final center = Offset(width / 2, height / 2);

            // Geomtería de la pantalla y márgenes para evitar superposición con la barra inferior y el FAB
            final minX = 24.0;
            final maxX = width - 24.0;
            final minY =
                widget.topMargin + (widget.topMargin > 160 ? 55.0 : 15.0);
            final maxYBottom = height - 85.0;
            final centerFabLeft = (width / 2) - 52.0;
            final centerFabRight = (width / 2) + 52.0;
            final maxYCenter = height - 130.0;
            final cutX = width - 85.0;
            final maxYRight = height - 230.0;

            return Stack(
              fit: StackFit.expand,
              children: widget.reportes.map((reporte) {
                final pos = LatLng(reporte.latitud, reporte.longitud);

                // Si está dentro de la vista normal de Google, no dibuja el radar
                if (_bounds!.contains(pos)) {
                  return const SizedBox.shrink();
                }

                final centerLat = camera.target.latitude;
                final centerLng = camera.target.longitude;

                final lat1 = centerLat * math.pi / 180;
                final lng1 = centerLng * math.pi / 180;
                final lat2 = pos.latitude * math.pi / 180;
                final lng2 = pos.longitude * math.pi / 180;

                final dLng = lng2 - lng1;

                final y = math.sin(dLng) * math.cos(lat2);
                final x =
                    math.cos(lat1) * math.sin(lat2) -
                    math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

                final bearingOriginal = math.atan2(y, x);

                // Ajustamos el bearing restando la rotación actual de la cámara del mapa
                final cameraBearingRad = camera.bearing * (math.pi / 180.0);
                final screenAngle = bearingOriginal - cameraBearingRad;

                // Calculamos el diferencial de eje visual en pantalla con el ángulo ajustado
                final dx = math.sin(screenAngle);
                final dy = -math.cos(screenAngle);

                if (dx.abs() < 0.0001 && dy.abs() < 0.0001) {
                  return const SizedBox.shrink();
                }

                double minT = double.infinity;

                void checkLine(double x1, double y1, double x2, double y2) {
                  double tCandidate = double.infinity;

                  if (y1 == y2) {
                    // Evaluación Horizontal
                    if (dy.abs() > 0.0001) {
                      tCandidate = (y1 - center.dy) / dy;
                      if (tCandidate > 0) {
                        double intersectX = center.dx + tCandidate * dx;
                        double minXBound = math.min(x1, x2);
                        double maxXBound = math.max(x1, x2);
                        if (intersectX >= minXBound - 0.1 &&
                            intersectX <= maxXBound + 0.1) {
                          if (tCandidate < minT) {
                            minT = tCandidate;
                          }
                        }
                      }
                    }
                  } else if (x1 == x2) {
                    // Evaluación Vertical
                    if (dx.abs() > 0.0001) {
                      tCandidate = (x1 - center.dx) / dx;
                      if (tCandidate > 0) {
                        double intersectY = center.dy + tCandidate * dy;
                        double minYBound = math.min(y1, y2);
                        double maxYBound = math.max(y1, y2);
                        if (intersectY >= minYBound - 0.1 &&
                            intersectY <= maxYBound + 0.1) {
                          if (tCandidate < minT) {
                            minT = tCandidate;
                          }
                        }
                      }
                    }
                  }
                }

                // Construcción y evaluación del perímetro de colisión envolvente:
                checkLine(minX, minY, maxX, minY); // Borde Superior
                checkLine(maxX, minY, maxX, maxYRight); // Borde Derecho Alto
                checkLine(maxX, maxYRight, cutX, maxYRight); // Techo de botones
                checkLine(
                  cutX,
                  maxYRight,
                  cutX,
                  maxYBottom,
                ); // Muro lateral botones
                checkLine(
                  cutX,
                  maxYBottom,
                  centerFabRight,
                  maxYBottom,
                ); // Inferior der
                checkLine(
                  centerFabRight,
                  maxYBottom,
                  centerFabRight,
                  maxYCenter,
                ); // Muro der fab
                checkLine(
                  centerFabRight,
                  maxYCenter,
                  centerFabLeft,
                  maxYCenter,
                ); // Techo fab
                checkLine(
                  centerFabLeft,
                  maxYCenter,
                  centerFabLeft,
                  maxYBottom,
                ); // Muro izq fab
                checkLine(
                  centerFabLeft,
                  maxYBottom,
                  minX,
                  maxYBottom,
                ); // Inferior izq
                checkLine(minX, maxYBottom, minX, minY); // Borde Izquierdo

                if (minT == double.infinity) {
                  return const SizedBox.shrink();
                }

                // Coordenadas finales de la intersección
                final indicatorX = center.dx + minT * dx;
                final indicatorY = center.dy + minT * dy;

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
                    angle:
                        screenAngle, // Rota exactamente hacia la orilla de la pantalla
                    child: GestureDetector(
                      onTap: () {
                        // Cambio de ! a ?
                        widget.mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(pos, 17.5),
                        );
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
