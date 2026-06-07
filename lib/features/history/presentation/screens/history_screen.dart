import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Esto ahora devuelve un AsyncValue<List<ReportModel>>
    final reportesAsync = ref.watch(misReportesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reportes'),
        backgroundColor: Colors.white.withOpacity(0.95),
        surfaceTintColor: Colors.white,
      ),
      body: reportesAsync.when(
        data: (reportes) {
          if (reportes.isEmpty) {
            return const Center(
              child: Text('Aún no has hecho ningún reporte.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reportes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // Extraemos el objeto modelo
              final reporte = reportes[index];

              final fotoUrl = reporte.fotoUrl;
              final especie = reporte.especie;
              final colorDominante = reporte.colorDominante;
              final referencias = reporte.referencias;

              return Card(
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: fotoUrl != null && fotoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            fotoUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
                  title: Text(
                    '$especie - $colorDominante',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    referencias,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Enviamos el ReportModel a la siguiente pantalla
                    context.push('/report-detail', extra: reporte);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error al cargar historial: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.pets, color: Colors.redAccent),
    );
  }
}
