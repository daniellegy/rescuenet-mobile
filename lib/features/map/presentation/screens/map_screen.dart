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

  Widget _buildReportMarker(Color urgencyColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: urgencyColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: urgencyColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.warning_rounded, color: urgencyColor, size: 24),
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
                      maxZoom: 25,
                      // La interacción queda limpia y libre de bucles
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
                        errorTileCallback: (tile, error, stackTrace) {},
                      ),
                      MarkerLayer(
                        rotate: true,
                        markers: [
                          ...reportesAsync.maybeWhen(
                            data: (reportes) => reportes.map((reporte) {
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
                                        .push('/report-detail', extra: reporte)
                                        .then((_) {
                                          ref.refresh(
                                            reportesActivosMapaProvider,
                                          );
                                          ref.refresh(miRescateActivoProvider);
                                        });
                                  },
                                  child: _buildReportMarker(
                                    reporte.colorUrgencia,
                                  ),
                                ),
                              );
                            }).toList(),
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
                            ref.refresh(reportesActivosMapaProvider);
                            ref.refresh(miRescateActivoProvider);
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
