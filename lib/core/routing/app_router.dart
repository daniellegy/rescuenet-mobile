import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    // Más adelante agregaremos aquí la ruta del '/mapa'
  ],
);
