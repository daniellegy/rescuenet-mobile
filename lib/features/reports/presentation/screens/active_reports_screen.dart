import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/active_reports_provider.dart';

class ActiveReportsScreen extends ConsumerWidget {
  const ActiveReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportesAsync = ref.watch(activeReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergencias Activas',
          style: TextStyle(color: Colors.red),
        ),
        backgroundColor: Colors.white.withOpacity(0.95),
      ),
      body: reportesAsync.when(
        data: (reportes) {
          if (reportes.isEmpty)
            return const Center(
              child: Text('No hay rescates pendientes en este momento.'),
            );

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reportes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              final colorEmergencia = reporte.colorUrgencia;
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: colorEmergencia,
                    width: 1.5,
                  ), // Borde dinámico
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: reporte.fotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            reporte.fotoUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.warning, color: colorEmergencia, size: 40),
                  title: Text(
                    'Emergencia: ${reporte.especie} (${reporte.urgencia.toUpperCase()})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorEmergencia, // Texto dinámico
                    ),
                  ),
                  subtitle: const Text(
                    'Toca para ver ubicación y aceptar rescate.',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context
                        .push('/report-detail', extra: reporte)
                        .then((_) => ref.refresh(activeReportsProvider));
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al obtener datos.')),
      ),
    );
  }
}
