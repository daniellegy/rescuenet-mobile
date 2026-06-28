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

// 1. NUEVOS IMPORTS: Necesarios para poder actualizar los datos en tiempo real
import 'features/map/presentation/providers/map_markers_provider.dart';
import 'features/reports/presentation/providers/my_active_rescue_provider.dart';
import 'features/reports/presentation/providers/active_reports_provider.dart';

// 2. LLAVE GLOBAL: Nos permitirá mostrar un aviso visual emergente sin importar en qué pantalla estés
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

    // Escenario 3 (NUEVO): La app está ABIERTA (Primer plano) y alguien emite una alerta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // A. Obligamos a Riverpod a desechar la caché del mapa y buscar los nuevos reportes al instante
      ref.invalidate(reportesActivosMapaProvider);
      ref.invalidate(miRescateActivoProvider);
      ref.invalidate(activeReportsProvider);

      // B. Mostramos una pequeña alerta visual para que el usuario sepa que el mapa acaba de cambiar
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.notification_important_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🚨 ¡Nueva emergencia reportada! Actualizando mapa...',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  void _abrirDetallesReporte(RemoteMessage message) {
    if (message.data.containsKey('reporte')) {
      try {
        final Map<String, dynamic> reportMap = jsonDecode(
          message.data['reporte'],
        );
        final reporteModel = ReportModel.fromJson(reportMap);

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
      scaffoldMessengerKey:
          scaffoldMessengerKey, // 3. INYECTAMOS LA LLAVE GLOBAL AQUÍ
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: const Color.fromARGB(255, 202, 40, 28),
          secondary: Colors.redAccent,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
