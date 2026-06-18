import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _mostrarModalRoles(BuildContext context, WidgetRef ref, int rolActualId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecciona tu Rol de Usuario',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rol actual: ${rolActualId == 2 ? "Voluntario" : "Reportante"}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // OPCIÓN: VOLUNTARIO 
                _buildOpcionRol(
                  context: context,
                  ref: ref,
                  titulo: 'Voluntario',
                  subtitulo: 'Deseo ayudar activamente en los rescates de animales.',
                  icon: Icons.handshake,
                  idRol: 2,
                  seleccionado: rolActualId == 2,
                ),
                const SizedBox(height: 12),

                // OPCIÓN: REPORTANTE 
                _buildOpcionRol(
                  context: context,
                  ref: ref,
                  titulo: 'Reportante',
                  subtitulo: 'Principalmente publico reportes de animales en riesgo.',
                  icon: Icons.campaign,
                  idRol: 1,
                  seleccionado: rolActualId == 1,
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
    required IconData icon,
    required int idRol,
    required bool seleccionado,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context); 
        try {
          await ref.read(userProfileProvider.notifier).actualizarCampo(role: idRol);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el rol: $e')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? Colors.redAccent : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (seleccionado)
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoTelefono(BuildContext context, WidgetRef ref, String telefonoActual) {
    final controller = TextEditingController(text: telefonoActual);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Teléfono', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de Teléfono',
              hintText: 'Ingresa tu nuevo número',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoTelefono = controller.text.trim();
                if (nuevoTelefono.isNotEmpty) {
                  Navigator.pop(context); 
                  try {
                    await ref.read(userProfileProvider.notifier).actualizarCampo(telefono: nuevoTelefono);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cambiar el teléfono: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: profileAsync.when(
        data: (usuario) {
          final int currentRole = usuario['role'] ?? 1;
          final String currentPhone = usuario['telefono'] ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Datos de la Cuenta', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)
              ),
              const SizedBox(height: 10),
              
              // 1. Nombre
              ListTile(
                leading: const Icon(Icons.person, color: Colors.redAccent),
                title: const Text('Nombre'),
                subtitle: Text(usuario['nombre_completo'] ?? 'Sin registrar'),
              ),
              const Divider(),
              
              // 2. ID de Usuario
              ListTile(
                leading: const Icon(Icons.badge, color: Colors.redAccent),
                title: const Text('ID de Usuario'),
                subtitle: Text(authState.userId?.toString() ?? 'No disponible'), 
              ),
              const Divider(),
              
              // 3. Tipo de Usuario / Rol 
              ListTile(
                leading: const Icon(Icons.assignment_ind, color: Colors.redAccent),
                title: const Text('Tipo de Usuario (Rol)'),
                subtitle: Text(currentRole == 2 ? 'VOLUNTARIO' : 'REPORTANTE'),
                trailing: const Icon(Icons.edit, size: 18, color: Colors.redAccent),
                onTap: () => _mostrarModalRoles(context, ref, currentRole),
              ),
              const Divider(),
              
              // 4. Correo Electrónico
              ListTile(
                leading: const Icon(Icons.email, color: Colors.redAccent),
                title: const Text('Correo Electrónico'),
                subtitle: Text(usuario['email'] ?? 'Sin registrar'),
              ),
              const Divider(),
              
              // 5. Teléfono de Contacto 
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.redAccent),
                title: const Text('Teléfono de Contacto'),
                subtitle: Text(currentPhone.isNotEmpty ? currentPhone : 'Sin registrar'),
                trailing: const Icon(Icons.edit, size: 18, color: Colors.redAccent),
                onTap: () => _mostrarDialogoTelefono(context, ref, currentPhone),
              ),
              const Divider(height: 40),
              
              // 6. Botón de Cerrar Sesión 
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
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