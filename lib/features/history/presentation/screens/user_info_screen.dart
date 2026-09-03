import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

void _mostrarImagenExpandida(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            maxScale: 4.0,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

final userStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, userId) async {
      final dio = ref.watch(dioProvider).instance;
      final response = await dio.get('/auth/usuario/$userId/estadisticas');
      return response.data as Map<String, dynamic>;
    });

class UserInfoScreen extends ConsumerWidget {
  final int userId;
  const UserInfoScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider(userId));
    final isMyProfile = ref.watch(authProvider).userId == userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Usuario'),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configuración',
              onPressed: () {
                context.push('/settings');
              },
            ),
        ],
      ),
      body: statsAsync.when(
        data: (datos) {
          final nombre = datos['nombre_completo'] ?? 'Usuario';
          final foto = datos['foto_perfil'];
          final esVoluntario = datos['role'] == 2;
          final reportesCreados =
              int.tryParse(datos['reportes_creados'].toString()) ?? 0;
          final rescatesRealizados =
              int.tryParse(datos['rescates_realizados'].toString()) ?? 0;
          final bool perfilPrivado = datos['perfil_privado'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (foto != null) {
                      _mostrarImagenExpandida(context, foto);
                    }
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: foto != null ? NetworkImage(foto) : null,
                    child: foto == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: esVoluntario
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    esVoluntario
                        ? 'Voluntario de Rescate'
                        : 'Ciudadano Reportante',
                    style: TextStyle(
                      color: esVoluntario
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatCard(
                        context: context,
                        label: 'Reportes Emitidos',
                        count: reportesCreados.toString(),
                        icon: Icons.campaign_rounded,
                        color: Colors.blue,
                        isMyProfile: isMyProfile,
                        isPrivate: perfilPrivado,
                        targetUserId: userId,
                        userName: nombre,
                        targetTabIndex: 0, // Índice 0: Reportados
                      ),
                      if (esVoluntario) ...[
                        const SizedBox(width: 16),
                        _buildStatCard(
                          context: context,
                          label: 'Rescates Concluidos',
                          count: rescatesRealizados.toString(),
                          icon: Icons.volunteer_activism,
                          color: Colors.green,
                          isMyProfile: isMyProfile,
                          isPrivate: perfilPrivado,
                          targetUserId: userId,
                          userName: nombre,
                          targetTabIndex: 1, // Índice 1: Rescatados
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error al cargar datos: $err')),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String count,
    required IconData icon,
    required Color color,
    required bool isMyProfile,
    required bool isPrivate,
    required int targetUserId,
    required String userName,
    required int targetTabIndex, // Añadido para controlar la redirección
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            if (isMyProfile) {
              // Para el propio perfil siempre abrimos el Historial global
              context.go('/map');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.push('/reports', extra: {'initialIndex': 1});
                }
              });
            } else {
              if (isPrivate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La información de este usuario es privada.'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                // Pasamos targetTabIndex a la nueva pantalla
                context.push(
                  '/public-user-reports',
                  extra: {
                    'userId': targetUserId,
                    'userName': userName,
                    'initialIndex': targetTabIndex,
                  },
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
