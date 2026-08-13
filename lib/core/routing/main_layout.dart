import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../features/map/presentation/widgets/map_bottom_nav_bar.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/location_service.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final cameraService = ref.read(cameraServiceProvider);
            final locationService = ref.read(locationServiceProvider);
            final pos = await locationService.getCurrentPosition();
            final pickedFile = await cameraService.takePicture();
            if (pickedFile != null && context.mounted) {
              context.push(
                '/create-report',
                extra: {
                  'lat': pos.latitude,
                  'lng': pos.longitude,
                  'imagePath': pickedFile.path,
                },
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceAll('Exception: ', '')),
                ),
              );
            }
          }
        },
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
