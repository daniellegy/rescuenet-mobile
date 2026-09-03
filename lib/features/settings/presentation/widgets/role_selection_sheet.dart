import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../providers/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';

class RoleSelectionSheet extends ConsumerWidget {
  final int rolActualId;
  final String? curpActual;

  const RoleSelectionSheet({
    super.key,
    required this.rolActualId,
    required this.curpActual,
  });

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
        Navigator.pop(parentContext);
      }
    } catch (e) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
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

  Future<void> _handleOpcionRol(
    BuildContext parentContext,
    BuildContext modalContext,
    WidgetRef ref,
    int rolTarget,
    String titulo,
  ) async {
    // Si es el mismo rol, solo cerramos
    if (rolTarget == rolActualId) {
      Navigator.pop(modalContext);
      return;
    }

    // Validaciones de casos activos
    if (rolActualId == 1) {
      final historial = ref.read(misReportesProvider).value ?? [];
      final tieneActivos = historial.any(
        (r) => r.estado != 'Rescatado' && r.estado != 'Falsa_Alarma',
      );
      if (tieneActivos) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'No puedes cambiar a Voluntario porque tienes reportes de emergencia activos. Ciérralos primero.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(modalContext);
        return;
      }
    } else if (rolActualId == 2) {
      final miRescate = ref.read(miRescateActivoProvider).value;
      if (miRescate != null) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'No puedes cambiar a Reportante porque tienes un rescate en proceso. Finalízalo o abórtalo primero.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(modalContext);
        return;
      }
    }

    // Procesamiento de Manifiesto
    String? tokenFCM;
    if (rolTarget == 2) {
      final acepto = await _mostrarManifiestoVoluntario(parentContext);
      if (!acepto) {
        Navigator.pop(modalContext); // Cerramos porque el usuario canceló
        return;
      }
      try {
        final messaging = FirebaseMessaging.instance;
        NotificationSettings settings = await messaging
            .getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        }
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          tokenFCM = await messaging.getToken();
        }
      } catch (e) {
        debugPrint('Error solicitando permisos FCM en cambio de rol: $e');
      }
    }

    // Si el bottom sheet por alguna razón externa se cerró, abortamos.
    if (!parentContext.mounted) {
      return;
    }

    // Continuamos con CURP o procesamos el cambio directo
    if (rolTarget == 2 && (curpActual == null || curpActual!.trim().isEmpty)) {
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
  }

  Widget _buildOpcionRol({
    required BuildContext parentContext,
    required BuildContext modalContext,
    required WidgetRef ref,
    required String titulo,
    required String subtitulo,
    required bool isSelected,
    required int rolTarget,
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
      onTap: () =>
          _handleOpcionRol(parentContext, modalContext, ref, rolTarget, titulo),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
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
              parentContext: context,
              modalContext: context,
              ref: ref,
              titulo: 'Reportante',
              subtitulo: 'Solo quiero reportar casos',
              isSelected: rolActualId == 1,
              rolTarget: 1,
            ),
            const Divider(),
            _buildOpcionRol(
              parentContext: context,
              modalContext: context,
              ref: ref,
              titulo: 'Voluntario',
              subtitulo: 'Quiero rescatar y recibir alertas',
              isSelected: rolActualId == 2,
              rolTarget: 2,
            ),
          ],
        ),
      ),
    );
  }
}
