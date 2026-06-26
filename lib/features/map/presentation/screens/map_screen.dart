import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/camera_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';

const _kAppBarBg = Color(0xE6FFFFFF);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? myPosition;
  late final MapController _mapController;
  String _filtroUrgencia = 'todos'; // Estados: 'todos', 'alta', 'media', 'baja'
  bool _showUrgencyMenu = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      if (position.latitude.isNaN || position.longitude.isNaN) {
        throw Exception(
          'El hardware del GPS retornó coordenadas no numéricas.',
        );
      }

      setState(() {
        myPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _takePhotoAndNavigate() async {
    if (myPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }

    try {
      final cameraService = ref.read(cameraServiceProvider);
      final pickedFile = await cameraService.takePicture();

      if (pickedFile != null && mounted) {
        context.push(
          '/create-report',
          extra: {
            'lat': myPosition!.latitude,
            'lng': myPosition!.longitude,
            'imagePath': pickedFile.path,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildReportMarker(Color urgencyColor, {bool isInProgress = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: urgencyColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        isInProgress ? Icons.hourglass_top_rounded : Icons.warning_rounded,
        color: urgencyColor,
        size: 24,
      ),
    );
  }

  // BARRA FLOTANTE VERTICAL
  Widget _buildVerticalFilterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterChip('Todos', 'todos', Colors.blue),
          const SizedBox(height: 8),
          _buildFilterChip('Alta', 'alta', Colors.red),
          const SizedBox(height: 8),
          _buildFilterChip('Media', 'media', Colors.orange),
          const SizedBox(height: 8),
          _buildFilterChip('Baja', 'baja', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final bool isSelected = _filtroUrgencia == value;
    return ChoiceChip(
      label: SizedBox(
        width: 46, // Ancho fijo para mantener la simetría de la columna
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.transparent,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _filtroUrgencia = value;
          });
        }
      },
    );
  }

  Widget get _buildUserMarker => const RepaintBoundary(
    child: Icon(Icons.person_pin, color: Colors.red, size: 40),
  );

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
    final reportesAsync = ref.watch(reportesActivosMapaProvider);
    final miRescateAsync = ref.watch(miRescateActivoProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Mapa de rescate'),
        backgroundColor: _kAppBarBg,
        actions: [
          reportesAsync.maybeWhen(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            orElse: () => IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: () {
                ref.invalidate(reportesActivosMapaProvider);
                ref.invalidate(miRescateActivoProvider);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: myPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                RepaintBoundary(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: myPosition!,
                      initialZoom: 18,
                      minZoom: 5,
                      maxZoom: 19,
                      cameraConstraint: CameraConstraint.contain(
                        bounds: LatLngBounds(
                          const LatLng(-90.0, -180.0),
                          const LatLng(90.0, 180.0),
                        ),
                      ),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        enableMultiFingerGestureRace: false,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
                        additionalOptions: {
                          'accessToken': mapboxToken,
                          'id': 'mapbox/streets-v12',
                        },
                        evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                      ),
                      MarkerLayer(
                        rotate: true,
                        markers: [
                          ...reportesAsync.maybeWhen(
                            data: (reportes) {
                              return reportes
                                  .where((r) {
                                    if (_filtroUrgencia == 'todos') {
                                      return true;
                                    }
                                    return r.urgencia.toLowerCase() ==
                                        _filtroUrgencia;
                                  })
                                  .map((reporte) {
                                    final bool estaEnProceso =
                                        reporte.estado
                                            .toString()
                                            .trim()
                                            .toUpperCase() ==
                                        'EN_PROCESO';

                                    return Marker(
                                      point: LatLng(
                                        reporte.latitud,
                                        reporte.longitud,
                                      ),
                                      width: 50,
                                      height: 50,
                                      rotate: true,
                                      child: GestureDetector(
                                        onTap: () {
                                          context
                                              .push(
                                                '/report-detail',
                                                extra: reporte,
                                              )
                                              .then((_) {
                                                ref.invalidate(
                                                  reportesActivosMapaProvider,
                                                );
                                                ref.invalidate(
                                                  miRescateActivoProvider,
                                                );
                                              });
                                        },
                                        child: _buildReportMarker(
                                          reporte.colorUrgencia,
                                          isInProgress: estaEnProceso,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList();
                            },
                            orElse: () => [],
                          ),
                          if (myPosition != null)
                            Marker(
                              point: myPosition!,
                              width: 50,
                              height: 50,
                              rotate: true,
                              child: _buildUserMarker,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // RADAR PERIFÉRICO CORREGIDO
                reportesAsync.maybeWhen(
                  data: (reportes) {
                    final reportesFiltrados = reportes.where((r) {
                      if (_filtroUrgencia == 'todos') return true;
                      return r.urgencia.toLowerCase() == _filtroUrgencia;
                    }).toList();

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return StreamBuilder<MapEvent>(
                          stream: _mapController.mapEventStream,
                          builder: (context, snapshot) {
                            if (!mounted) return const SizedBox.shrink();

                            final camera = _mapController.camera;
                            final width = constraints.maxWidth;
                            final height = constraints.maxHeight;

                            if (width == 0 || height == 0)
                              return const SizedBox.shrink();

                            final center = Offset(width / 2, height / 2);

                            const topMargin = 24.0;
                            const sideMargin = 24.0;
                            const bottomMargin = 130.0;

                            final minX = sideMargin;
                            final maxX = width - sideMargin;
                            final minY = topMargin;
                            final maxY = height - bottomMargin;

                            return Stack(
                              // CLAVE DE LA CORRECCIÓN: Evita el colapso a 0x0 cuando hay SizedBox.shrink
                              fit: StackFit.expand,
                              children: reportesFiltrados.map((reporte) {
                                final pos = LatLng(
                                  reporte.latitud,
                                  reporte.longitud,
                                );

                                if (camera.visibleBounds.contains(pos)) {
                                  return const SizedBox.shrink();
                                }

                                final lat1 =
                                    camera.center.latitude * math.pi / 180;
                                final lng1 =
                                    camera.center.longitude * math.pi / 180;
                                final lat2 = pos.latitude * math.pi / 180;
                                final lng2 = pos.longitude * math.pi / 180;

                                final dLng = lng2 - lng1;
                                final y = math.sin(dLng) * math.cos(lat2);
                                final x =
                                    math.cos(lat1) * math.sin(lat2) -
                                    math.sin(lat1) *
                                        math.cos(lat2) *
                                        math.cos(dLng);

                                final bearing = math.atan2(y, x);
                                final dx = math.sin(bearing);
                                final dy = -math.cos(bearing);

                                if (dx.abs() < 0.0001 && dy.abs() < 0.0001) {
                                  return const SizedBox.shrink();
                                }

                                double t = double.infinity;

                                if (dx.abs() > 0.0001) {
                                  if (dx > 0)
                                    t = math.min(t, (maxX - center.dx) / dx);
                                  if (dx < 0)
                                    t = math.min(t, (minX - center.dx) / dx);
                                }

                                if (dy.abs() > 0.0001) {
                                  if (dy > 0)
                                    t = math.min(t, (maxY - center.dy) / dy);
                                  if (dy < 0)
                                    t = math.min(t, (minY - center.dy) / dy);
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
                                    reporte.estado
                                        .toString()
                                        .trim()
                                        .toUpperCase() ==
                                    'EN_PROCESO';

                                return Positioned(
                                  left: indicatorX - 18,
                                  top: indicatorY - 18,
                                  child: Transform.rotate(
                                    angle: bearing,
                                    child: GestureDetector(
                                      onTap: () {
                                        _mapController.move(pos, 17);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: reporte.colorUrgencia,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: reporte.colorUrgencia
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
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
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                // FILTRO UBICADO EN LATERAL DERECHO
                Positioned(
                  bottom: 160, 
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'toggle_filter_btn', // Evita conflictos de hero tags con el botón de cámara
                        mini: true,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueGrey,
                        elevation: 4,
                        onPressed: () {
                          setState(() {
                            _showUrgencyMenu = !_showUrgencyMenu;
                          });
                        },
                        child: Icon(
                          _showUrgencyMenu ? Icons.close_rounded : Icons.filter_list_rounded,
                        ),
                      ),
                      // El menú solo se renderiza si _showUrgencyMenu es true
                      if (_showUrgencyMenu) ...[
                        const SizedBox(height: 12),
                        _buildVerticalFilterSelector(),
                      ],
                    ],
                  ),
                ),

                // TARJETA DE RESCATE ACTIVO EN LA PARTE SUPERIOR
                miRescateAsync.maybeWhen(
                  data: (rescate) {
                    if (rescate == null) return const SizedBox.shrink();
                    return Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          context.push('/report-detail', extra: rescate).then((
                            _,
                          ) {
                            ref.invalidate(reportesActivosMapaProvider);
                            ref.invalidate(miRescateActivoProvider);
                          });
                        },
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: rescate.colorUrgencia,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.warning_amber_rounded,
                              color: rescate.colorUrgencia,
                              size: 36,
                            ),
                            title: const Text(
                              'Tienes un rescate en curso',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${rescate.especie} - Estado: ${rescate.estadoFormateado}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                          ),
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                Positioned(
                  bottom: 110,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    elevation: 4,
                    child: const Icon(Icons.my_location),
                    onPressed: () {
                      if (myPosition != null) {
                        _mapController.move(myPosition!, 18);
                      } else {
                        _fetchCurrentLocation();
                      }
                    },
                  ),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _takePhotoAndNavigate,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_a_photo, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.map, color: Colors.redAccent),
              tooltip: 'Mapa',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.grey),
              tooltip: 'Mi Historial',
              onPressed: () => context.push('/history'),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.grey),
              tooltip: 'Emergencias Activas',
              onPressed: () => context.push('/active-reports'),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              tooltip: 'Configuración',
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
