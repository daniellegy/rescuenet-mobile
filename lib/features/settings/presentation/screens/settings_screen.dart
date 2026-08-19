import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/map_limit_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/role_selection_sheet.dart';
import '../widgets/settings_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final mapLimit = ref.watch(mapLimitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: perfilAsync.when(
        data: (datos) {
          final nombre = datos['nombre_completo'] ?? 'Usuario';
          final telefono = datos['telefono'] ?? 'Sin registrar';
          final email = datos['email'] ?? 'Sin registrar';
          final curp = datos['curp'];
          final String? fotoUrl = datos['foto_perfil'];
          final int rolActualId = datos['role'] ?? 1;
          final int radioNotificaciones = datos['radio_notificaciones'] ?? 30;
          final String? tokenFCMActual = datos['fcm_token'];
          final bool notificacionesActivas =
              tokenFCMActual != null && tokenFCMActual.trim().isNotEmpty;

          return ListView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 120.0,
            ),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (authState.userId != null) {
                          context.push('/user-info', extra: authState.userId);
                        }
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: fotoUrl != null
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: fotoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => const ProfilePhotoSheet(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
                title: const Text('Modo Oscuro'),
                subtitle: const Text('Cambiar la apariencia de la aplicación'),
                value: isDark,
                activeThumbColor: Colors.redAccent,
                onChanged: (bool value) {
                  ref.read(themeProvider.notifier).toggleTheme(value);
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 24),
              const Text(
                'Mi Cuenta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.orange,
                ),
                title: const Text('Rol en la Plataforma'),
                subtitle: Text(rolActualId == 2 ? 'Voluntario' : 'Reportante'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => RoleSelectionSheet(
                      rolActualId: rolActualId,
                      curpActual: curp,
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                  color: Colors.blueAccent,
                ),
                title: const Text('Correo Electrónico'),
                subtitle: Text(email),
                trailing: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditDataDialog(
                      titulo: 'Correo',
                      valorActual: email,
                      campoBaseDatos: 'email',
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.green),
                title: const Text('Teléfono Móvil'),
                subtitle: Text(telefono),
                trailing: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditDataDialog(
                      titulo: 'Teléfono',
                      valorActual: telefono,
                      campoBaseDatos: 'telefono',
                    ),
                  );
                },
              ),
              if (rolActualId == 2 &&
                  curp != null &&
                  curp.toString().isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge, color: Colors.blueGrey),
                  title: const Text(
                    'CURP Oficial',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  subtitle: Text(
                    curp,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Text(
                'Preferencias de Alertas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                secondary: const Icon(
                  Icons.notifications_active,
                  color: Colors.teal,
                ),
                title: const Text('Notificaciones Push'),
                subtitle: Text(
                  notificacionesActivas ? 'Activadas' : 'Desactivadas',
                ),
                value: notificacionesActivas,
                activeThumbColor: Colors.redAccent,
                onChanged: (bool value) async {
                  if (value) {
                    try {
                      final messaging = FirebaseMessaging.instance;
                      NotificationSettings settings = await messaging
                          .requestPermission(
                            alert: true,
                            badge: true,
                            sound: true,
                          );

                      if (settings.authorizationStatus ==
                          AuthorizationStatus.authorized) {
                        final token = await messaging.getToken();
                        if (token != null) {
                          await ref
                              .read(userProfileProvider.notifier)
                              .actualizarCampo(fcmToken: token);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Permiso denegado. Actívalo manualmente en la configuración de tu dispositivo (Ajustes > Aplicaciones).',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint(
                        'Error al activar notificaciones desde switch: $e',
                      );
                    }
                  } else {
                    try {
                      await ref
                          .read(userProfileProvider.notifier)
                          .actualizarCampo(fcmToken: 'CLEAR');
                    } catch (e) {
                      debugPrint(
                        'Error al desactivar notificaciones desde switch: $e',
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.radar, color: Colors.purple),
                title: const Text('Radio de Notificaciones'),
                subtitle: Text('$radioNotificaciones km de área para alertas'),
                trailing: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        RadiusSliderDialog(radioActual: radioNotificaciones),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.pin_drop, color: Colors.redAccent),
                title: const Text('Límite en Mapa'),
                subtitle: Text('Mostrar hasta $mapLimit reportes simultáneos'),
                trailing: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        MapLimitSliderDialog(limiteActual: mapLimit),
                  );
                },
              ),
              const Divider(height: 40),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Salir de tu cuenta actual en este dispositivo',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const LogoutDialog(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Eliminar Cuenta',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Dar de baja tu usuario y borrar tus datos de RescueNet',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const DeleteAccountDialog(),
                  );
                },
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 12),
                Text(
                  'No se pudieron cargar los datos de perfil:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
