import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Rescates'),
        actions: [
          // Botón para probar el cierre de sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Llamamos a la función logout de tu cerebro
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Aquí irá el mapa interactivo (Mapbox)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
