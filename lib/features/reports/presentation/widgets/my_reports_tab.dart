import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/domain/models/report_model.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'tactical_report_cards.dart';

class MyReportsTab extends ConsumerStatefulWidget {
  final bool isDark;
  const MyReportsTab({super.key, required this.isDark});

  @override
  ConsumerState<MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends ConsumerState<MyReportsTab> {
  bool _verMasAlertas = false;
  bool _verMasRescates = false;
  bool _verMasConcluidos = false;

  Widget _buildReportSection(
    String title,
    List<ReportModel> items,
    bool isDark,
    IconData icon,
    bool showAll,
    VoidCallback onToggle,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final displayItems = showAll ? items : items.take(4).toList();
    final bool canExpand = items.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Archivo Black',
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (canExpand)
                TextButton(
                  onPressed: onToggle,
                  child: Text(
                    showAll ? 'Ver menos' : 'Ver más',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        if (showAll)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) =>
                TacticalListCard(reporte: displayItems[index], isDark: isDark),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20.0,
                    right: index == displayItems.length - 1 ? 20.0 : 0,
                  ),
                  child: TacticalCarouselCard(
                    reporte: displayItems[index],
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final historialAsync = ref.watch(misReportesProvider);
    final currentUserId = ref.watch(authProvider).userId;

    return historialAsync.when(
      data: (reportes) {
        final alertasActivas = reportes
            .where(
              (r) =>
                  r.usuarioReportadorId == currentUserId &&
                  r.estado != 'Rescatado',
            )
            .toList();
        final misRescatesConcluidos = reportes
            .where(
              (r) =>
                  r.usuarioRescatistaId == currentUserId &&
                  r.estado != 'Rescatado',
            )
            .toList();
        final misCierres = reportes
            .where((r) => r.estado == 'Rescatado')
            .toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportSection(
                'Mis alertas',
                alertasActivas,
                widget.isDark,
                Icons.campaign_rounded,
                _verMasAlertas,
                () => setState(() => _verMasAlertas = !_verMasAlertas),
              ),
              const SizedBox(height: 24),
              _buildReportSection(
                'Mis rescates',
                misRescatesConcluidos,
                widget.isDark,
                Icons.health_and_safety_rounded,
                _verMasRescates,
                () => setState(() => _verMasRescates = !_verMasRescates),
              ),
              const SizedBox(height: 24),
              _buildReportSection(
                'Mis cierres',
                misCierres,
                widget.isDark,
                Icons.check_circle_outline_rounded,
                _verMasConcluidos,
                () => setState(() => _verMasConcluidos = !_verMasConcluidos),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          const Center(child: Text('Error al cargar tu historial')),
    );
  }
}
