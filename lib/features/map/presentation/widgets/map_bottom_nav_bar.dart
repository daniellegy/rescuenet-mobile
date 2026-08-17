import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class MapBottomNavBar extends ConsumerWidget {
  const MapBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String currentLocation = GoRouterState.of(context).uri.path;
    final userProfile = ref.watch(userProfileProvider).value;
    final String? photoUrl = userProfile?['foto_perfil'];

    Color getColor(String path) {
      if (currentLocation.startsWith(path)) {
        return Colors.redAccent;
      }
      return isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    }

    // AQUÍ VA LA MAGIA MAESTRA: Navegación de Instancia Única
    void _manejarNavegacion(String targetPath) {
      if (currentLocation == targetPath) return; // Si ya estás ahí, ignóralo

      // Lista de pantallas que funcionan como "Modales Transparentes" sobre el mapa
      final bool currentlyInModal = currentLocation == '/reports' || 
                                    currentLocation == '/community' || 
                                    currentLocation == '/user-info';
                                    
      final bool targetIsModal = targetPath == '/reports' || 
                                 targetPath == '/community' || 
                                 targetPath == '/user-info';

      if (targetPath == '/map') {
        if (currentlyInModal) {
          // Destruye el modal suavemente y regresa al cascarón del mapa
          context.pop(); 
        } else {
          context.go('/map');
        }
      } else if (targetIsModal) {
        if (currentlyInModal) {
          // Si cambias entre modales (Ej. de Reportes a Perfil), REEMPLAZA para no apilarlos al infinito
          context.pushReplacement(targetPath, extra: targetPath == '/user-info' ? ref.read(authProvider).userId : null);
        } else {
          // Si vienes del mapa limpio, APILA el modal por primera vez
          context.push(targetPath, extra: targetPath == '/user-info' ? ref.read(authProvider).userId : null);
        }
      } else {
        context.push(targetPath);
      }
    }

    Widget buildNavItem(
      String label,
      IconData iconData,
      String path,
    ) {
      final color = getColor(path);
      return Expanded(
        child: GestureDetector(
          onTap: () => _manejarNavegacion(path),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (label == 'Yo' && photoUrl != null)
                CircleAvatar(
                  radius: 11,
                  backgroundImage: NetworkImage(photoUrl),
                )
              else
                Icon(iconData, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: currentLocation.startsWith(path)
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return BottomAppBar(
      height: 50.0,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      padding: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          children: [
            buildNavItem('Mapa', Icons.map_rounded, '/map'),
            buildNavItem('Reportes', Icons.pets_rounded, '/reports'),
            const SizedBox(width: 56), // Espacio para la cámara flotante
            buildNavItem('Comunidad', Icons.people_alt_outlined, '/community'),
            buildNavItem('Yo', Icons.person_outline_rounded, '/user-info'),
          ],
        ),
      ),
    );
  }
}