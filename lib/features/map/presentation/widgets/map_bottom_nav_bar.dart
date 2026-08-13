import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MapBottomNavBar extends ConsumerWidget {
  const MapBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Obtenemos la ruta actual para saber en qué pestaña estamos
    final String currentLocation = GoRouterState.of(context).uri.path;

    // Función auxiliar para determinar el color del ícono
    Color getColor(String path) {
      if (currentLocation.startsWith(path)) {
        return Colors.redAccent;
      }
      return isDark ? Colors.grey.shade400 : Colors.grey;
    }

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.map, color: getColor('/map')),
            tooltip: 'Mapa',
            onPressed: () => context.go('/map'),
          ),
          IconButton(
            icon: Icon(Icons.history, color: getColor('/history')),
            tooltip: 'Mi Historial',
            // Cambiado de push() a go() para un comportamiento correcto de tabs
            onPressed: () => context.go('/history'),
          ),
          const SizedBox(width: 48), // Espaciador central para el botón FAB
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: getColor('/active-reports'),
            ),
            tooltip: 'Emergencias Activas',
            // Cambiado de push() a go() para un comportamiento correcto de tabs
            onPressed: () => context.go('/active-reports'),
          ),
          IconButton(
            icon: Icon(Icons.person, color: getColor('/user-info')),
            tooltip: 'Perfil',
            onPressed: () {
              final userId = ref.read(authProvider).userId;
              if (userId != null) {
                // Mantenemos push para poder usar el botón de retroceso nativo al salir del perfil
                context.push('/user-info', extra: userId);
              }
            },
          ),
        ],
      ),
    );
  }
}
