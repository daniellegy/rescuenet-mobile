import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MapDrawer extends ConsumerWidget {
  const MapDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style:
                          Theme.of(context).appBarTheme.titleTextStyle
                              ?.copyWith(fontSize: 28) ??
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
              leading: const Icon(Icons.pets),
              title: const Text('Reportes Activos'),
              onTap: () {
                Navigator.pop(context);
                context.push('/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                final userId = ref.read(authProvider).userId;
                if (userId != null) {
                  context.push('/user-info', extra: userId);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Comunidad'),
              onTap: () {
                Navigator.pop(context);
                context.push('/community');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial'),
              onTap: () {
                Navigator.pop(context);
                context.push('/reports', extra: {'initialIndex': 1});
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Contacto a Instituciones'),
              onTap: () {
                Navigator.pop(context);
                context.push('/institutions');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
