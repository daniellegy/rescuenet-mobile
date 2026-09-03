import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:rescuenet_mobile/features/map/presentation/widgets/map_bottom_nav_bar.dart';
import 'package:rescuenet_mobile/core/services/camera_service.dart';
import 'package:rescuenet_mobile/core/services/location_service.dart';

// Clase personalizada para controlar la ubicación exacta y animación del botón
class SinkingFabLocation extends FloatingActionButtonLocation {
  const SinkingFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Mantener centrado en el eje X
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;

    // Posición Y base: Center Docked (Mitad asomado arriba, mitad dentro de la barra)
    double fabY = scaffoldGeometry.contentBottom - (fabHeight / 2.0);

    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    // Si aparece un SnackBar, calculamos el hundimiento
    if (snackBarHeight > 0.0) {
      // Se limita el hundimiento para que quede estéticamente anclado al menú inferior sin desaparecer
      double maxSink = fabHeight / 1.3;
      double sinkAmount = math.min(snackBarHeight, maxSink);
      fabY += sinkAmount;
    }

    return Offset(fabX, fabY);
  }
}

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: child,
      floatingActionButtonLocation: const SinkingFabLocation(),
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
