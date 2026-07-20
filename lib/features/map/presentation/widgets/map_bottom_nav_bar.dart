import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MapBottomNavBar extends StatelessWidget {
  const MapBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.redAccent),
            tooltip: 'Mapa',
            onPressed: () {}, // Ya estamos en el mapa
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            tooltip: 'Mi Historial',
            onPressed: () => context.push('/history'),
          ),
          const SizedBox(
            width: 48,
          ), // Espaciador central para el botón FAB (Cámara)
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.grey),
            tooltip: 'Emergencias Activas',
            onPressed: () => context.push('/active-reports'),
          ),
          IconButton(
            icon: const Icon(Icons.pets_rounded, color: Colors.grey),
            tooltip: 'Perros Perdidos',
            onPressed: () => context.push('/lost-dogs'),
          ),
        ],
      ),
    );
  }
}
