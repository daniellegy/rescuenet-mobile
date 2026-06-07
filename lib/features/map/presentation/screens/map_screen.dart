import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/camera_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? myPosition;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
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

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Mapa de rescates'),
        backgroundColor: Colors.white.withOpacity(0.9),
        actions: [
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
                  markers: [
                    Marker(
                      point: myPosition!,
                      child: const Icon(
                        Icons.person_pin,
                        color: Colors.red,
                        size: 40,
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
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.red),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.article, color: Colors.red),
                onPressed: () => context.push('/history'),
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
