import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart'; // Importamos el destino

// Ahora el router es un Provider para poder leer el AuthProvider
final routerProvider = Provider<GoRouter>((ref) {
  // 1. Creamos un "puente" para que GoRouter escuche a Riverpod
  final authStateNotifier = ValueNotifier<AuthState>(ref.read(authProvider));

  // Si el authProvider cambia (ej. el usuario se loguea), actualizamos el puente
  ref.listen<AuthState>(authProvider, (_, next) {
    authStateNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable:
        authStateNotifier, // 2. GoRouter se recarga automáticamente si esto cambia
    // 3. LA MAGIA: El Guardia de Rutas
    redirect: (context, state) {
      final isLogged = authStateNotifier.value.isLogged;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      // REGLA A: Si NO está logueado y trata de ir a una pantalla prohibida, lo regresamos al Login
      if (!isLogged && !isGoingToLogin && !isGoingToRegister) {
        return '/login';
      }

      // REGLA B: Si YA está logueado y trata de ver el Login o Registro, lo expulsamos al Mapa
      if (isLogged && (isGoingToLogin || isGoingToRegister)) {
        return '/map';
      }

      // En cualquier otro caso, dejamos que navegue normalmente
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    ],
  );
});
