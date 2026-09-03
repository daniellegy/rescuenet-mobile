import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/camera_service.dart';
import '../providers/settings_provider.dart';
import '../providers/map_limit_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../map/presentation/providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/active_reports_provider.dart';

class ProfilePhotoSheet extends ConsumerWidget {
  const ProfilePhotoSheet({super.key});

  Future<void> _procesarSubidaFoto({
    required ScaffoldMessengerState messenger,
    required dynamic cameraService,
    required dynamic userProfileNotifier,
    required bool fromGallery,
  }) async {
    try {
      final pickedFile = await cameraService.takePicture(
        fromGallery: fromGallery,
        cropImage: true,
      );
      if (pickedFile != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Subiendo foto...'),
            duration: Duration(seconds: 2),
          ),
        );

        await userProfileNotifier.actualizarFotoPerfil(pickedFile.path);

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Foto actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              final messenger = ScaffoldMessenger.of(context);
              final cameraService = ref.read(cameraServiceProvider);
              final userProfileNotifier = ref.read(
                userProfileProvider.notifier,
              );

              Navigator.pop(context);

              await _procesarSubidaFoto(
                messenger: messenger,
                cameraService: cameraService,
                userProfileNotifier: userProfileNotifier,
                fromGallery: false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.green),
            title: const Text('Elegir de la galería'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final cameraService = ref.read(cameraServiceProvider);
              final userProfileNotifier = ref.read(
                userProfileProvider.notifier,
              );

              Navigator.pop(context);

              await _procesarSubidaFoto(
                messenger: messenger,
                cameraService: cameraService,
                userProfileNotifier: userProfileNotifier,
                fromGallery: true,
              );
            },
          ),
        ],
      ),
    );
  }
}

class EditDataDialog extends ConsumerStatefulWidget {
  final String titulo;
  final String valorActual;
  final String campoBaseDatos;

  const EditDataDialog({
    super.key,
    required this.titulo,
    required this.valorActual,
    required this.campoBaseDatos,
  });

  @override
  ConsumerState<EditDataDialog> createState() => _EditDataDialogState();
}

class _EditDataDialogState extends ConsumerState<EditDataDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorActual);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Actualizar ${widget.titulo}'),
      content: TextField(
        controller: _controller,
        keyboardType: widget.campoBaseDatos == 'telefono'
            ? TextInputType.phone
            : TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Ingresa tu nuevo ${widget.titulo}',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () async {
            final nuevoValor = _controller.text.trim();
            if (widget.campoBaseDatos == 'email') {
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(nuevoValor)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formato de correo inválido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            } else if (widget.campoBaseDatos == 'telefono') {
              final phoneRegex = RegExp(r'^\d{10}$');
              if (!phoneRegex.hasMatch(nuevoValor)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El teléfono debe tener 10 dígitos'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
            }

            if (nuevoValor.isNotEmpty && nuevoValor != widget.valorActual) {
              Navigator.pop(context);
              try {
                if (widget.campoBaseDatos == 'telefono') {
                  await ref
                      .read(userProfileProvider.notifier)
                      .actualizarCampo(telefono: nuevoValor);
                } else if (widget.campoBaseDatos == 'email') {
                  await ref
                      .read(userProfileProvider.notifier)
                      .actualizarCampo(email: nuevoValor);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dato actualizado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
  }
}

class RadiusSliderDialog extends ConsumerStatefulWidget {
  final int radioActual;
  const RadiusSliderDialog({super.key, required this.radioActual});

  @override
  ConsumerState<RadiusSliderDialog> createState() => _RadiusSliderDialogState();
}

class _RadiusSliderDialogState extends ConsumerState<RadiusSliderDialog> {
  late int _radioSeleccionado;

  @override
  void initState() {
    super.initState();
    _radioSeleccionado = widget.radioActual;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Radio de Alertas (km)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Recibir notificaciones de nuevas emergencias a un máximo de $_radioSeleccionado km a la redonda.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _radioSeleccionado.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: '$_radioSeleccionado km',
            activeColor: Colors.purple,
            onChanged: (val) =>
                setState(() => _radioSeleccionado = val.toInt()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            if (_radioSeleccionado != widget.radioActual) {
              try {
                await ref
                    .read(userProfileProvider.notifier)
                    .actualizarCampo(radioNotificaciones: _radioSeleccionado);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Radio actualizado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
  }
}

class MapLimitSliderDialog extends ConsumerStatefulWidget {
  final int limiteActual;
  const MapLimitSliderDialog({super.key, required this.limiteActual});

  @override
  ConsumerState<MapLimitSliderDialog> createState() =>
      _MapLimitSliderDialogState();
}

class _MapLimitSliderDialogState extends ConsumerState<MapLimitSliderDialog> {
  late int _limiteSeleccionado;

  @override
  void initState() {
    super.initState();
    _limiteSeleccionado = widget.limiteActual;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Límite de Emergencias'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mostrar un máximo de $_limiteSeleccionado emergencias activas en el mapa y en listas para no saturar la pantalla.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _limiteSeleccionado.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: '$_limiteSeleccionado',
            activeColor: Colors.redAccent,
            onChanged: (val) =>
                setState(() => _limiteSeleccionado = val.toInt()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            if (_limiteSeleccionado != widget.limiteActual) {
              await ref
                  .read(mapLimitProvider.notifier)
                  .updateLimit(_limiteSeleccionado);
              ref.invalidate(reportesActivosMapaProvider);
              ref.invalidate(activeReportsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
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
  }
}

class LogoutDialog extends ConsumerWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Has cerrado sesión correctamente.'),
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cerrar sesión: $e'),
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
  }
}

class DeleteAccountDialog extends ConsumerWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(context);
            try {
              await ref.read(authProvider.notifier).eliminarCuentaEnServidor();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tu cuenta ha sido eliminada correctamente.'),
                    backgroundColor: Colors.black87,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar cuenta: $e'),
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
  }
}
