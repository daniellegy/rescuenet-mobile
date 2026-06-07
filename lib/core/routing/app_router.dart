import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart'; // <- Ruta actualizada
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/history/presentation/screens/report_detail_screen.dart';
import '../../features/history/domain/models/report_model.dart'; // <- Nuevo import

final routerProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ValueNotifier<AuthState>(ref.read(authProvider));

  ref.listen<AuthState>(authProvider, (_, next) {
    authStateNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final isLogged = authStateNotifier.value.isLogged;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      if (!isLogged && !isGoingToLogin && !isGoingToRegister) {
        return '/login';
      }

      if (isLogged && (isGoingToLogin || isGoingToRegister)) {
        return '/map';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/report-detail',
        builder: (context, state) {
          final reporteData =
              state.extra as ReportModel; // <- Ahora usa el modelo
          return ReportDetailScreen(reporte: reporteData);
        },
      ),
      GoRoute(
        path: '/create-report',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CreateReportScreen(
            lat: extra['lat'] as double,
            lng: extra['lng'] as double,
            imagePath: extra['imagePath'] as String,
          );
        },
      ),
    ],
  );
});
