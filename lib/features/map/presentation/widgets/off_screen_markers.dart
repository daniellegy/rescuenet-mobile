import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../history/domain/models/report_model.dart';

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
    _updateBounds(); // Llamada inicial
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

  // AQUÍ VA EL CAMBIO: Usamos los límites reales de Google Maps de forma ultra-rápida
  Future<void> _updateBounds() async {
    if (widget.mapController == null) return;
    try {
      final bounds = await widget.mapController!.getVisibleRegion();
      if (mounted) {
        setState(() {
          _bounds = bounds;
        });
      }
    } catch (e) {
      // Ignorar errores en movimientos bruscos
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
            // Esperamos a que los límites estén calculados
            if (camera == null || widget.mapController == null || _bounds == null) {
              return const SizedBox.shrink();
            }

            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final center = Offset(width / 2, height / 2);

            final sideMargin = 24.0;
            final bottomMargin = 130.0;
            final minX = sideMargin;
            final maxX = width - sideMargin;
            final minY = widget.topMargin;
            final maxY = height - bottomMargin;

            return Stack(
              fit: StackFit.expand,
              children: widget.reportes.map((reporte) {
                final pos = LatLng(reporte.latitud, reporte.longitud);

                // 1. Verificación perfecta: Si está dentro de los límites de Google, NO dibujes el radar.
                if (_bounds!.contains(pos)) {
                  return const SizedBox.shrink(); 
                }

                // 2. Cálculo del Ángulo (Bearing)
                final centerLat = camera.target.latitude;
                final centerLng = camera.target.longitude;

                final lat1 = centerLat * math.pi / 180;
                final lng1 = centerLng * math.pi / 180;
                final lat2 = pos.latitude * math.pi / 180;
                final lng2 = pos.longitude * math.pi / 180;

                final dLng = lng2 - lng1;
                final y = math.sin(dLng) * math.cos(lat2);
                final x = math.cos(lat1) * math.sin(lat2) -
                    math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
                final bearing = math.atan2(y, x);

                final dx = math.sin(bearing);
                final dy = -math.cos(bearing);

                if (dx.abs() < 0.0001 && dy.abs() < 0.0001) {
                  return const SizedBox.shrink();
                }

                // 3. Intersección con los bordes
                double t = double.infinity;
                if (dx.abs() > 0.0001) {
                  if (dx > 0) t = math.min(t, (maxX - center.dx) / dx);
                  if (dx < 0) t = math.min(t, (minX - center.dx) / dx);
                }
                if (dy.abs() > 0.0001) {
                  if (dy > 0) t = math.min(t, (maxY - center.dy) / dy);
                  if (dy < 0) t = math.min(t, (minY - center.dy) / dy);
                }

                if (t == double.infinity || t.isNaN) return const SizedBox.shrink();

                final indicatorX = center.dx + t * dx;
                final indicatorY = center.dy + t * dy;

                if (indicatorX.isNaN || indicatorY.isNaN) return const SizedBox.shrink();

                final bool estaEnProceso =
                    reporte.estado.toString().trim().toUpperCase() == 'EN_PROCESO';

                return Positioned(
                  left: indicatorX - 18,
                  top: indicatorY - 18,
                  child: Transform.rotate(
                    angle: bearing,
                    child: GestureDetector(
                      onTap: () {
                        widget.mapController!.animateCamera(
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
                              color: reporte.colorUrgencia.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          estaEnProceso ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
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