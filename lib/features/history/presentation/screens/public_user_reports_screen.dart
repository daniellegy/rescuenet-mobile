import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../reports/presentation/widgets/tactical_report_cards.dart';
import '../providers/public_user_reports_provider.dart';

class PublicUserReportsScreen extends ConsumerWidget {
  final int userId;
  final String userName;
  final int initialIndex;

  const PublicUserReportsScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(publicUserReportsProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Actividad de $userName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: reportsAsync.when(
        data: (reportes) {
          final emitidos = reportes
              .where((r) => r.usuarioReportadorId == userId)
              .toList();
          final rescates = reportes
              .where((r) => r.usuarioRescatistaId == userId)
              .toList();

          return DefaultTabController(
            initialIndex: initialIndex,
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: Colors.blueAccent,
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'REPORTADOS'),
                    Tab(text: 'RESCATADOS'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildList(
                        emitidos,
                        isDark,
                        'Este usuario no ha emitido reportes públicos.',
                      ),
                      _buildList(
                        rescates,
                        isDark,
                        'Este usuario no ha realizado rescates públicos.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar datos: $e')),
      ),
    );
  }

  Widget _buildList(List reportes, bool isDark, String emptyMessage) {
    if (reportes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: reportes.length,
      itemBuilder: (context, index) {
        return TacticalListCard(reporte: reportes[index], isDark: isDark);
      },
    );
  }
}
