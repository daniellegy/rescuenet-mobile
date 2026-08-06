import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MapBottomNavBar extends StatelessWidget {
  const MapBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.redAccent),
            tooltip: 'Mapa',
            onPressed: () {}, // Ya estamos en el mapa
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              color: isDark ? Colors.grey.shade400 : Colors.grey,
            ),
            tooltip: 'Mi Historial',
            onPressed: () => context.push('/history'),
          ),
          const SizedBox(
            width: 48,
          ), // Espaciador central para el bot n FAB (Cámara)
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: isDark ? Colors.grey.shade400 : Colors.grey,
            ),
            tooltip: 'Emergencias Activas',
            onPressed: () => context.push('/active-reports'),
          ),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: isDark ? Colors.grey.shade400 : Colors.grey,
            ),
            tooltip: 'Mensajes',
            onPressed: () => context.push('/inbox'),
          ),
        ],
      ),
    );
  }
}
