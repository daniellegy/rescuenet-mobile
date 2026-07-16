import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/camera_service.dart';
import '../providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';

// Componentes modulares
import '../widgets/urgency_filter_menu.dart';
import '../widgets/active_rescue_card.dart';
import '../widgets/map_bottom_nav_bar.dart';
import '../widgets/off_screen_markers.dart';

const _kAppBarBg = Color(0xE6FFFFFF);

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? myPosition;
  late final MapController _mapController;
  String _filtroUrgencia = 'todos';
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

      ref.invalidate(reportesActivosMapaProvider);
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
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Configuración',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: myPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // CAPA PRINCIPAL DEL MAPA
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
                                  .where(
                                    (r) =>
                                        _filtroUrgencia == 'todos' ||
                                        r.urgencia.toLowerCase() ==
                                            _filtroUrgencia,
                                  )
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
                              child: const RepaintBoundary(
                                child: Icon(
                                  Icons.person_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // CAPA DE INDICADORES FUERA DE PANTALLA
                reportesAsync.maybeWhen(
                  data: (reportes) {
                    final reportesFiltrados = reportes.where((r) {
                      if (_filtroUrgencia == 'todos') return true;
                      return r.urgencia.toLowerCase() == _filtroUrgencia;
                    }).toList();

                    return OffScreenMarkers(
                      mapController: _mapController,
                      reportes: reportesFiltrados,
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

                // CAPA DE BOTONES FLOTANTES (Filtro y Ubicación)
                Positioned(
                  bottom: 200,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'toggle_filter_btn',
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
                          _showUrgencyMenu
                              ? Icons.close_rounded
                              : Icons.filter_list_rounded,
                        ),
                      ),
                      if (_showUrgencyMenu) ...[
                        const SizedBox(height: 12),
                        UrgencyFilterMenu(
                          currentFilter: _filtroUrgencia,
                          onFilterChanged: (newFilter) {
                            setState(() {
                              _filtroUrgencia = newFilter;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                Positioned(
                  bottom: 140,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'my_location_btn',
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

                // CAPA DE AVISO DE RESCATE ACTIVO
                miRescateAsync.maybeWhen(
                  data: (rescate) {
                    if (rescate == null) return const SizedBox.shrink();
                    return Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: ActiveRescueCard(rescate: rescate),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
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
      bottomNavigationBar: const MapBottomNavBar(),
    );
  }
}
