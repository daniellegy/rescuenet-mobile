import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_layout.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/lost_dogs/presentation/screens/lost_dogs_screen.dart';
import '../../features/reports/presentation/screens/create_report_screen.dart';
import '../../features/history/presentation/screens/report_detail_screen.dart';
import '../../features/history/domain/models/report_model.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/history/presentation/screens/search_radar.dart';
import '../../features/reports/presentation/screens/rescue_stepper_screen.dart';
import '../../features/history/presentation/screens/user_info_screen.dart';
import '../../features/messages/presentation/screens/inbox_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/community/presentation/screens/institutions_screen.dart';
import '../../features/history/presentation/screens/public_user_reports_screen.dart';

class TransparentRoute<T> extends Page<T> {
  final Widget child;
  const TransparentRoute({required this.child, super.key});

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      opaque: false, // CLAVE PARA MANTENER VIVO EL MAPA
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) => child,
    );
  }
}

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
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          GoRoute(
            path: '/lost-dogs',
            builder: (context, state) => const LostDogsScreen(),
          ),
          GoRoute(
            path: '/inbox',
            builder: (context, state) => const InboxScreen(),
          ),
          GoRoute(
            path: '/community',
            pageBuilder: (context, state) =>
                const TransparentRoute(child: CommunityScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) {
              int initialIndex = 0;
              if (state.extra != null) {
                final extraParams = state.extra as Map<String, dynamic>?;
                initialIndex = extraParams?['initialIndex'] as int? ?? 0;
              }
              return TransparentRoute(
                key: state.pageKey,
                child: ReportsScreen(initialIndex: initialIndex),
              );
            },
          ),
        ],
      ),
      // Moviendo /user-info fuera del ShellRoute soluciona el BUG de keyReservation
      // y garantiza la flecha nativa hacia atrás
      GoRoute(
        path: '/user-info',
        builder: (context, state) {
          final userId = state.extra as int;
          return UserInfoScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/public-user-reports',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final userId = extra['userId'] as int;
          final userName = extra['userName'] as String;
          return PublicUserReportsScreen(userId: userId, userName: userName);
        },
      ),
      GoRoute(
        path: '/report-detail',
        builder: (context, state) {
          final reporteData = state.extra as ReportModel;
          return ReportDetailScreen(reporte: reporteData);
        },
      ),
      GoRoute(
        path: '/search-radar',
        builder: (context, state) {
          final reporteData = state.extra as ReportModel;
          return SearchRadarScreen(reporte: reporteData);
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
      GoRoute(
        path: '/institutions',
        builder: (context, state) => const InstitutionsScreen(),
      ),
    ],
  );
});
