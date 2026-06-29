import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _mostrarModalRoles(
    BuildContext context,
    WidgetRef ref,
    int rolActualId,
    String? curpActual,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                  context: context,
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
                  context: context,
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
    required BuildContext context,
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
        Navigator.pop(context);
        if (rolTarget == rolActual) return;

        if (rolTarget == 2) {
          final acepto = await _mostrarManifiestoVoluntario(context);
          if (!acepto) return;
        }

        if (!context.mounted) return;

        if (rolTarget == 2 &&
            (curpActual == null || curpActual.trim().isEmpty)) {
          _mostrarDialogoRegistroCurp(context, ref);
        } else {
          _procesarCambioDeRol(context, ref, rolTarget, titulo, null);
        }
      },
    );
  }

  void _mostrarDialogoRegistroCurp(BuildContext context, WidgetRef ref) {
    final TextEditingController curpController = TextEditingController();
    final curpRegex = RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z\d]\d$');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () {
                final curpIngresada = curpController.text.trim().toUpperCase();

                if (!curpRegex.hasMatch(curpIngresada)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El formato del CURP es inválido.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                _procesarCambioDeRol(
                  context,
                  ref,
                  2,
                  'Voluntario',
                  curpIngresada,
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
    BuildContext context,
    WidgetRef ref,
    int rolTarget,
    String titulo,
    String? nuevaCurp,
  ) async {
    try {
      await ref
          .read(userProfileProvider.notifier)
          .actualizarCampo(role: rolTarget, curp: nuevaCurp);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cambiado a $titulo exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoDato(
    BuildContext context,
    WidgetRef ref,
    String titulo,
    String valorActual,
    String campoBaseDatos,
  ) {
    final TextEditingController controller = TextEditingController(
      text: valorActual,
    );

    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
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
                    ScaffoldMessenger.of(context).showSnackBar(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El teléfono debe tener 10 dígitos'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                if (nuevoValor.isNotEmpty && nuevoValor != valorActual) {
                  Navigator.pop(context);
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
      },
    );
  }

  void _mostrarDialogoRadio(
    BuildContext context,
    WidgetRef ref,
    int radioActual,
  ) {
    int radioSeleccionado = radioActual;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Radio de Alertas (km)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Verás reportes y recibirás alertas de rescates a un máximo de $radioSeleccionado km a la redonda.',
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (radioSeleccionado != radioActual) {
                      try {
                        await ref
                            .read(userProfileProvider.notifier)
                            .actualizarCampo(
                              radioNotificaciones: radioSeleccionado,
                            );
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
          },
        );
      },
    );
  }

  Future<bool> _mostrarManifiestoVoluntario(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text(
              'Manifiesto de Voluntario',
              style: TextStyle(fontSize: 18),
            ),
            content: const Text(
              'Declaro que los gastos derivados corren por mi cuenta u originados por financiamiento colectivo ajeno a la app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.white,
      ),
      body: perfilAsync.when(
        data: (datos) {
          final nombre = datos['nombre_completo'] ?? 'Usuario';
          final telefono = datos['telefono'] ?? 'Sin registrar';
          final email = datos['email'] ?? 'Sin registrar';
          final curp = datos['curp'];
          final int rolActualId = datos['role'] ?? 1;
          final int radioNotificaciones = datos['radio_notificaciones'] ?? 30;

          return ListView(
            // CORRECCIÓN: Padding bottom de 120 para liberar el BottomNavigationBar
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 120.0,
            ),
            children: [
              const SizedBox(height: 20),
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
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

              const Divider(height: 40),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
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
