import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MainMenuSheet extends ConsumerWidget {
  const MainMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style:
                        Theme.of(
                          context,
                        ).appBarTheme.titleTextStyle?.copyWith(fontSize: 28) ??
                        const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                    children: const [
                      TextSpan(
                        text: 'Rescue',
                        style: TextStyle(color: Colors.red),
                      ),
                      TextSpan(
                        text: 'Net',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/splash/rescuenet-logo-sinfondo-grande.png',
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.pets, color: Colors.red, size: 40),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.pets,
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
            title: const Text('Reportes Activos'),
            onTap: () {
              Navigator.pop(context);
              context.push('/reports');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.person,
              color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
            ),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              final userId = ref.read(authProvider).userId;
              if (userId != null) {
                context.push('/user-info', extra: userId);
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.people,
              color: isDark ? Colors.green.shade300 : Colors.green.shade700,
            ),
            title: const Text('Comunidad'),
            onTap: () {
              Navigator.pop(context);
              context.push('/community');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history,
              color: isDark ? Colors.purple.shade300 : Colors.purple.shade700,
            ),
            title: const Text('Historial'),
            onTap: () {
              Navigator.pop(context);
              context.push('/reports', extra: {'initialIndex': 1});
            },
          ),
          ListTile(
            leading: Icon(
              Icons.business,
              color: isDark ? Colors.teal.shade300 : Colors.teal.shade700,
            ),
            title: const Text('Contacto a Instituciones'),
            onTap: () {
              Navigator.pop(context);
              context.push('/institutions');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
