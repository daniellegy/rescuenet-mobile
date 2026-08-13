import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MapBottomNavBar extends ConsumerWidget {
  const MapBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => context.go('/map'),
          ),
          IconButton(
            icon: Icon(
              Icons.history,
              color: isDark ? Colors.grey.shade400 : Colors.grey,
            ),
            tooltip: 'Mi Historial',
            onPressed: () => context.push('/history'),
          ),
          const SizedBox(width: 48), // Espaciador central para el bot n FAB
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
              Icons.person,
              color: isDark ? Colors.grey.shade400 : Colors.grey,
            ),
            tooltip: 'Perfil',
            onPressed: () {
              final userId = ref.read(authProvider).userId;
              if (userId != null) {
                context.push('/user-info', extra: userId);
              }
            },
          ),
        ],
      ),
    );
  }
}
