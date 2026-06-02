import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Cambiamos la importación para usar el provider
import 'core/routing/app_router.dart';

void main() {
  runApp(const ProviderScope(child: RescueNetApp()));
}

// Cambiamos StatelessWidget por ConsumerWidget para leer providers
class RescueNetApp extends ConsumerWidget {
  const RescueNetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos nuestro nuevo routerProvider
    final appRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RescueNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          primary: const Color(0xFFD32F2F),
          secondary: const Color(0xFF722F37),
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter, // Aquí pasamos el router en vivo
    );
  }
}
