import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  // Envolvemos toda la app en un ProviderScope para que Riverpod funcione
  runApp(const ProviderScope(child: RescueNetApp()));
}

// === CONFIGURACIÓN DE RUTAS (GoRouter) ===
// Aquí definiremos todas las pantallas de la app (Feature-First)
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'RescueNet - Login / Home'),
    ),
    // Ejemplo de cómo agregaremos rutas después:
    // GoRoute(
    //   path: '/reporte',
    //   builder: (context, state) => const NuevoReporteScreen(),
    // ),
  ],
);

// === WIDGET PRINCIPAL DE LA APP ===
class RescueNetApp extends StatelessWidget {
  const RescueNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RescueNet Mobile',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de "DEBUG"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              Colors.deepOrange, // Color temático sugerido para "Rescate"
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Conectamos MaterialApp con GoRouter
      routerConfig: _router,
    );
  }
}

// === PANTALLA TEMPORAL (Placeholder) ===
// Borraremos esto cuando creemos nuestras verdaderas pantallas en la carpeta /features
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 20),
            Text(
              '¡Bienvenido a RescueNet!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const Text('El entorno base está listo para programar.'),
          ],
        ),
      ),
    );
  }
}
