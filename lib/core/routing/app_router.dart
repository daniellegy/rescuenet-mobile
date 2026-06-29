import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/history/presentation/screens/report_detail_screen.dart';
import '../../features/history/domain/models/report_model.dart';
import '../../features/reports/presentation/screens/active_reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/history/presentation/screens/search_radar.dart';
import '../../features/reports/presentation/screens/rescue_stepper_screen.dart';

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
        path: '/search-radar',
        builder: (context, state) {
          final reporteData =
              state.extra
                  as ReportModel; // Extrae el modelo que mandamos por extra
          return SearchRadarScreen(
            reporte: reporteData,
          ); // Inyecta el reporte al Radar
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
      GoRoute(
        path: '/active-reports',
        builder: (context, state) => const ActiveReportsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/rescue-stepper',
        builder: (context, state) {
          final reporteData = state.extra as ReportModel;
          return RescueStepperScreen(reporte: reporteData);
        },
      ),
    ],
  );
});
