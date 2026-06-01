import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Aquí está el cambio: usamos 'routing' en lugar de 'router'
import 'core/routing/app_router.dart';

void main() {
  runApp(
    // ProviderScope es obligatorio para que Riverpod funcione en toda la app
    const ProviderScope(child: RescueNetApp()),
  );
}

class RescueNetApp extends StatelessWidget {
  const RescueNetApp({super.key});

  // ... (código superior sin cambios)

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RescueNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              Colors.redAccent, // Rojo vivo como base para calcular el resto
          primary: const Color(0xFFD32F2F), // Rojo fuerte estándar para botones
          secondary: const Color(
            0xFF722F37,
          ), // Rojo vino para detalles secundarios
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
