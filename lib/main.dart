import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  // 1. SOLICITAR PERMISOS AL SISTEMA OPERATIVO
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // 2. OBTENER EL TOKEN ÚNICO DE TU CELULAR (Revisa tu terminal de VS Code)
  final token = await messaging.getToken();
  debugPrint('====================================');
  debugPrint('FCM TOKEN DE ESTE CELULAR:');
  debugPrint(token);
  debugPrint('====================================');

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
