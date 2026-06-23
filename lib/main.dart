import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/routing/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/history/domain/models/report_model.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  final container = ProviderContainer();
  await container.read(authProvider.notifier).restoreSession();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RescueNetApp(),
    ),
  );
}

class RescueNetApp extends ConsumerStatefulWidget {
  const RescueNetApp({super.key});

  @override
  ConsumerState<RescueNetApp> createState() => _RescueNetAppState();
}

class _RescueNetAppState extends ConsumerState<RescueNetApp> {
  @override
  void initState() {
    super.initState();
    _configurarToquesDeNotificacion();
  }

  void _configurarToquesDeNotificacion() async {
    // Escenario 1: La app está COMPLETAMENTE CERRADA y el usuario toca la notificación
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _abrirDetallesReporte(message);
    });

    // Escenario 2: La app está MINIMIZADA (segundo plano) y el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _abrirDetallesReporte(message);
    });
  }

  void _abrirDetallesReporte(RemoteMessage message) {
    // Verificamos que el paquete de datos oculto traiga la propiedad 'reporte'
    if (message.data.containsKey('reporte')) {
      try {
        final Map<String, dynamic> reportMap = jsonDecode(
          message.data['reporte'],
        );
        final reporteModel = ReportModel.fromJson(reportMap);

        // Se le da un pequeño retraso (500ms) para garantizar que el GoRouter
        // ya construyó el mapa de fondo antes de ponerle la pantalla de detalles encima.
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(routerProvider).push('/report-detail', extra: reporteModel);
        });
      } catch (e) {
        debugPrint("Error decodificando reporte de notificación: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Rescue Net',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: const Color.fromARGB(
            255,
            202,
            40,
            28,
          ), // Fuerza explícitamente el rojo vivo
          secondary: Colors.redAccent,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(),
        useMaterial3:
            true, // Si tu diseño original se sigue viendo raro, cambia esto a false
      ),
      routerConfig: router,
    );
  }
}
