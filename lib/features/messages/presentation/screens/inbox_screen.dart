import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history/presentation/providers/history_provider.dart';
import '../../../reports/presentation/widgets/canal_chat_sheet.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(misReportesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Mensajes'),
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      ),
      body: historialAsync.when(
        data: (reportes) {
          final activos = reportes
              .where(
                (r) =>
                    r.canalComunicacionHabilitado &&
                    r.canalComunicacionEstado == 'activo',
              )
              .toList();

          if (activos.isEmpty) {
            return const Center(
              child: Text(
                'No tienes conversaciones activas actualmente.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: activos.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final r = activos[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Card(
                  elevation: 2,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.colorUrgencia.withValues(alpha: 0.15),
                      child: Icon(Icons.pets, color: r.colorUrgencia),
                    ),
                    title: Text(
                      'Rescate de ${r.especie}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Toca para abrir el chat de coordinación',
                    ),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        builder: (ctx) => CanalChatSheet(
                          reporteId: r.id,
                          onCanalCerrado: () {
                            ref.invalidate(misReportesProvider);
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error al cargar la bandeja: $e')),
      ),
    );
  }
}
