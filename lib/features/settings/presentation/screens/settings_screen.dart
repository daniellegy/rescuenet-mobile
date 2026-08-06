import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/map_limit_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../map/presentation/providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/active_reports_provider.dart';
import '../../../../core/services/camera_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _mostrarOpcionesDeFoto(BuildContext parentContext, WidgetRef ref) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Actualizar foto de perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tomar fotografía'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  await _procesarSubidaFoto(
                    parentContext,
                    ref,
                    fromGallery: false,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Elegir de la galería'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  await _procesarSubidaFoto(
                    parentContext,
                    ref,
                    fromGallery: true,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarSubidaFoto(
    BuildContext context,
    WidgetRef ref, {
    required bool fromGallery,
  }) async {
    try {
      final cameraService = ref.read(cameraServiceProvider);
      final pickedFile = await cameraService.takePicture(
        fromGallery: fromGallery,
      );
      if (pickedFile != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo foto...'),
            duration: Duration(seconds: 2),
          ),
        );
        await ref
            .read(userProfileProvider.notifier)
            .actualizarFotoPerfil(pickedFile.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarModalRoles(
    BuildContext parentContext,
    WidgetRef ref,
    int rolActualId,
    String? curpActual,
  ) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecciona tu Rol de Usuario',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rol actual: ${rolActualId == 2 ? "Voluntario" : "Reportante"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _buildOpcionRol(
                  parentContext: parentContext,
                  modalContext: modalContext,
                  ref: ref,
                  titulo: 'Reportante',
                  subtitulo: 'Solo quiero reportar casos',
                  isSelected: rolActualId == 1,
                  rolTarget: 1,
                  rolActual: rolActualId,
                  curpActual: curpActual,
                ),
                const Divider(),
                _buildOpcionRol(
                  parentContext: parentContext,
                  modalContext: modalContext,
                  ref: ref,
                  titulo: 'Voluntario',
                  subtitulo: 'Quiero rescatar y recibir alertas',
                  isSelected: rolActualId == 2,
                  rolTarget: 2,
                  rolActual: rolActualId,
                  curpActual: curpActual,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpcionRol({
    required BuildContext parentContext,
    required BuildContext modalContext,
    required WidgetRef ref,
    required String titulo,
    required String subtitulo,
    required bool isSelected,
    required int rolTarget,
    required int rolActual,
    required String? curpActual,
  }) {
    return ListTile(
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitulo),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.circle_outlined),
      onTap: () async {
        Navigator.pop(modalContext);
        if (rolTarget == rolActual) {
          return;
        }

        String? tokenFCM;
        if (rolTarget == 2) {
          final acepto = await _mostrarManifiestoVoluntario(parentContext);
          if (!acepto) {
            return;
          }
          try {
            final messaging = FirebaseMessaging.instance;
            NotificationSettings settings = await messaging
                .getNotificationSettings();
            if (settings.authorizationStatus !=
                AuthorizationStatus.authorized) {
              settings = await messaging.requestPermission(
                alert: true,
                badge: true,
                sound: true,
              );
            }
            if (settings.authorizationStatus ==
                AuthorizationStatus.authorized) {
              tokenFCM = await messaging.getToken();
            }
          } catch (e) {
            debugPrint('Error solicitando permisos FCM en cambio de rol: $e');
          }
        }

        if (!parentContext.mounted) {
          return;
        }

        if (rolTarget == 2 &&
            (curpActual == null || curpActual.trim().isEmpty)) {
          _mostrarDialogoRegistroCurp(parentContext, ref, tokenFCM);
        } else {
          _procesarCambioDeRol(
            parentContext,
            ref,
            rolTarget,
            titulo,
            null,
            tokenFCM,
          );
        }
      },
    );
  }

  void _mostrarDialogoRegistroCurp(
    BuildContext parentContext,
    WidgetRef ref,
    String? tokenFCM,
  ) {
    final TextEditingController curpController = TextEditingController();
    final curpRegex = RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z\d]\d$');

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Completar Registro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Para proteger la identidad de nuestra red de rescate, ser Voluntario requiere que nos proporciones tu CURP.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: curpController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 18,
                decoration: const InputDecoration(
                  labelText: 'Ingresa tu CURP',
                  border: OutlineInputBorder(),
                  counterText: "",
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () {
                final curpIngresada = curpController.text.trim().toUpperCase();
                if (!curpRegex.hasMatch(curpIngresada)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('El formato del CURP es inválido.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                _procesarCambioDeRol(
                  parentContext,
                  ref,
                  2,
                  'Voluntario',
                  curpIngresada,
                  tokenFCM,
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Confirmar Rol'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _procesarCambioDeRol(
    BuildContext parentContext,
    WidgetRef ref,
    int rolTarget,
    String titulo,
    String? nuevaCurp,
    String? tokenFCM,
  ) async {
    try {
      await ref
          .read(userProfileProvider.notifier)
          .actualizarCampo(
            role: rolTarget,
            curp: nuevaCurp,
            fcmToken: tokenFCM,
          );
      ref.read(authProvider.notifier).updateLocalRole(rolTarget);
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text('Cambiado a $titulo exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoDato(
    BuildContext parentContext,
    WidgetRef ref,
    String titulo,
    String valorActual,
    String campoBaseDatos,
  ) {
    final TextEditingController controller = TextEditingController(
      text: valorActual,
    );
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Actualizar $titulo'),
          content: TextField(
            controller: controller,
            keyboardType: campoBaseDatos == 'telefono'
                ? TextInputType.phone
                : TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Ingresa tu nuevo $titulo',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final nuevoValor = controller.text.trim();
                if (campoBaseDatos == 'email') {
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(nuevoValor)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Formato de correo inválido'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                } else if (campoBaseDatos == 'telefono') {
                  final phoneRegex = RegExp(r'^\d{10}$');
                  if (!phoneRegex.hasMatch(nuevoValor)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('El teléfono debe tener 10 dígitos'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                if (nuevoValor.isNotEmpty && nuevoValor != valorActual) {
                  Navigator.pop(dialogContext);
                  try {
                    if (campoBaseDatos == 'telefono') {
                      await ref
                          .read(userProfileProvider.notifier)
                          .actualizarCampo(telefono: nuevoValor);
                    } else if (campoBaseDatos == 'email') {
                      await ref
                          .read(userProfileProvider.notifier)
                          .actualizarCampo(email: nuevoValor);
                    }
                    if (parentContext.mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text('Dato actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (parentContext.mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoRadio(
    BuildContext parentContext,
    WidgetRef ref,
    int radioActual,
  ) {
    int radioSeleccionado = radioActual;
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Radio de Alertas (km)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver reportes y recibir alertas de rescates a un máximo de $radioSeleccionado km a la redonda.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: radioSeleccionado.toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: '$radioSeleccionado km',
                    activeColor: Colors.purple,
                    onChanged: (val) =>
                        setState(() => radioSeleccionado = val.toInt()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (radioSeleccionado != radioActual) {
                      try {
                        await ref
                            .read(userProfileProvider.notifier)
                            .actualizarCampo(
                              radioNotificaciones: radioSeleccionado,
                            );
                        ref.invalidate(reportesActivosMapaProvider);
                        ref.invalidate(activeReportsProvider);

                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Radio actualizado exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoLimiteMapa(
    BuildContext parentContext,
    WidgetRef ref,
    int limiteActual,
  ) {
    int limiteSeleccionado = limiteActual;
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Límite de Emergencias'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mostrar un máximo de $limiteSeleccionado emergencias activas en el mapa y en listas para no saturar la pantalla.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: limiteSeleccionado.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9, // Incrementos de 5
                    label: '$limiteSeleccionado',
                    activeColor: Colors.redAccent,
                    onChanged: (val) {
                      setState(() {
                        limiteSeleccionado = val.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    if (limiteSeleccionado != limiteActual) {
                      await ref
                          .read(mapLimitProvider.notifier)
                          .updateLimit(limiteSeleccionado);

                      ref.invalidate(reportesActivosMapaProvider);
                      ref.invalidate(activeReportsProvider);

                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Límite actualizado exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _mostrarManifiestoVoluntario(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text(
              'Manifiesto de Voluntario',
              style: TextStyle(fontSize: 18),
            ),
            content: const Text(
              'Declaro que los gastos derivados corren por mi cuenta u originados por financiamiento colectivo ajeno a la app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Acepto la responsabilidad'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Obtenemos el límite actual configurado
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
                        onTap: () => _mostrarOpcionesDeFoto(context, ref),
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
                activeColor: Colors.redAccent,
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
                onTap: () =>
                    _mostrarModalRoles(context, ref, rolActualId, curp),
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
                onTap: () =>
                    _mostrarDialogoDato(context, ref, 'Correo', email, 'email'),
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
                onTap: () => _mostrarDialogoDato(
                  context,
                  ref,
                  'Teléfono',
                  telefono,
                  'telefono',
                ),
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
                activeColor: Colors.redAccent,
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
                title: const Text('Radio de Búsqueda'),
                subtitle: Text('$radioNotificaciones km de área para alertas'),
                trailing: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onTap: () =>
                    _mostrarDialogoRadio(context, ref, radioNotificaciones),
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
                onTap: () => _mostrarDialogoLimiteMapa(context, ref, mapLimit),
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
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text('¿Cerrar Sesión?'),
                          ],
                        ),
                        content: const Text(
                          'Estás a punto de salir de tu cuenta en RescueNet. '
                          'Para volver a reportar emergencias o rastrear rescates en tiempo real '
                          'necesitarás ingresar tus credenciales nuevamente.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              try {
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Has cerrado sesión correctamente.',
                                      ),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al cerrar sesión: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Cerrar Sesión'),
                          ),
                        ],
                      );
                    },
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
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('¿Eliminar cuenta?'),
                          ],
                        ),
                        content: const Text(
                          'Esta acción es irreversible. Se borrarán tus datos personales, el historial '
                          'de alertas que has emitido y tus registros de rescates '
                          'de los servidores de RescueNet',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              try {
                                await ref
                                    .read(authProvider.notifier)
                                    .eliminarCuentaEnServidor();
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tu cuenta ha sido eliminada correctamente.',
                                      ),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al eliminar cuenta: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Eliminar cuenta'),
                          ),
                        ],
                      );
                    },
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
