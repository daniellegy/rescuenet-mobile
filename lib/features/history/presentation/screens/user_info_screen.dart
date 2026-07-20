import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';

// Provider exclusivo para traer las estadísticas dinámicas
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Usuario'),
        backgroundColor: Colors.white,
      ),
      body: statsAsync.when(
        data: (datos) {
          final nombre = datos['nombre_completo'] ?? 'Usuario';
          final foto = datos['foto_perfil'];
          final esVoluntario = datos['role'] == 2;

          // Postgres count viene como String en algunos drivers, así que parseamos
          final reportesCreados =
              int.tryParse(datos['reportes_creados'].toString()) ?? 0;
          final rescatesRealizados =
              int.tryParse(datos['rescates_realizados'].toString()) ?? 0;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: foto != null ? NetworkImage(foto) : null,
                  child: foto == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
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

                // SOLUCIÓN APLICADA: IntrinsicHeight + CrossAxisAlignment.stretch
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatCard(
                        'Reportes Emitidos',
                        reportesCreados.toString(),
                        Icons.campaign_rounded,
                        Colors.blue,
                      ),
                      if (esVoluntario) ...[
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Rescates Concluidos',
                          rescatesRealizados.toString(),
                          Icons.volunteer_activism,
                          Colors.green,
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

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centra el contenido verticalmente
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
    );
  }
}
