import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MapBottomNavBar extends ConsumerWidget {
  const MapBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String currentLocation = GoRouterState.of(context).uri.path;

    Color getColor(String path) {
      if (currentLocation.startsWith(path)) {
        return Colors.redAccent;
      }
      return isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    }

    Widget buildNavItem(String label, IconData iconData, String path, {VoidCallback? customAction}) {
      final color = getColor(path);
      return Expanded(
        child: GestureDetector(
          onTap: customAction ?? () => context.go(path),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5, 
                  fontWeight: currentLocation.startsWith(path) ? FontWeight.bold : FontWeight.w500,
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
            buildNavItem('Comunidad', Icons.people_alt_outlined, '/community', customAction: () {
              context.push('/community'); 
            }),
            
            buildNavItem('Reportes', Icons.pets_rounded, '/reports', customAction: () {
              context.push('/reports');
            }),

            const SizedBox(width: 56), 

            buildNavItem('Mensajes', Icons.chat_bubble_outline_rounded, '/inbox'),
            
            buildNavItem('Yo', Icons.person_outline_rounded, '/user-info', customAction: () {
              final userId = ref.read(authProvider).userId;
              if (userId != null) {
                context.push('/user-info', extra: userId);
              }
            }),
          ],
        ),
      ),
    );
  }
}