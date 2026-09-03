import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../reports/domain/models/report_model.dart';
import '../providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';

class ActiveRescueCard extends ConsumerWidget {
  final ReportModel rescate;

  const ActiveRescueCard({super.key, required this.rescate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push('/rescue-stepper', extra: rescate).then((_) {
          ref.invalidate(reportesActivosMapaProvider);
          ref.invalidate(miRescateActivoProvider);
        });
      },
      child: Card(
        elevation: 8,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: rescate.colorUrgencia, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Icon(
            Icons.warning_amber_rounded,
            color: rescate.colorUrgencia,
            size: 36,
          ),
          title: const Text(
            'Tienes un rescate en curso',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${rescate.especie} - Estado: ${rescate.estadoFormateado}',
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
