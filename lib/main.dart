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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RescueNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      routerConfig: appRouter, // Conectamos GoRouter
    );
  }
}
