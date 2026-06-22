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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

// Se añade TickerProviderStateMixin para poder manejar animaciones
class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  LatLng? myPosition;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configuración del controlador de animación (duración de 1.2 segundos por ciclo)
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..repeat(
          reverse: true,
        ); // El repeat con reverse crea el efecto de latido constante

    // Curva de escalado suave para no deformar los gráficos 2D
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    // Es CRÍTICO destruir el controlador para evitar fugas de memoria
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      if (position.latitude.isNaN ||
          position.longitude.isNaN ||
          position.latitude.isInfinite ||
          position.longitude.isInfinite) {
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

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
    final reportesAsync = ref.watch(reportesActivosMapaProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Mapa de rescates'),
        backgroundColor: Colors.white.withOpacity(0.9),
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
              onPressed: () => ref.invalidate(reportesActivosMapaProvider),
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
          : FlutterMap(
              options: MapOptions(
                initialCenter: myPosition!,
                initialZoom: 18,
                minZoom: 5,
                maxZoom: 25,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
                  additionalOptions: {
                    'accessToken': mapboxToken,
                    'id': 'mapbox/streets-v12',
                  },
                ),
                MarkerLayer(
                  rotate: true,
                  markers: [
                    ...reportesAsync.maybeWhen(
                      data: (reportes) => reportes
                          .map(
                            (reporte) => Marker(
                              point: LatLng(reporte.latitud, reporte.longitud),
                              width: 50,
                              height: 50,
                              rotate: true,
                              child: GestureDetector(
                                onTap: () {
                                  context.push(
                                    '/report-detail',
                                    extra: reporte,
                                  );
                                },
                                // Animación aplicada al marcador del reporte
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.orange,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      orElse: () => [],
                    ),
                    if (myPosition != null &&
                        !myPosition!.latitude.isNaN &&
                        !myPosition!.longitude.isNaN)
                      Marker(
                        point: myPosition!,
                        width: 50,
                        height: 50,
                        rotate: true,
                        // Animación aplicada al marcador del usuario
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: const Icon(
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
