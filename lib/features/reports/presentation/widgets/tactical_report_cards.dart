import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../history/domain/models/report_model.dart';

Widget _buildFallbackIcon() => Container(
  width: 45,
  height: 45,
  color: Colors.grey.shade300,
  child: const Icon(Icons.pets, color: Colors.grey),
);

class TacticalListCard extends StatelessWidget {
  final ReportModel reporte;
  final bool isDark;

  const TacticalListCard({
    super.key,
    required this.reporte,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/report-detail', extra: reporte),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: reporte.colorUrgencia, width: 6),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: reporte.fotoUrl != null
                  ? Image.network(
                      reporte.fotoUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                    )
                  : _buildFallbackIcon(),
            ),
            title: Text(
              reporte.especie,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Estado: ${reporte.estadoFormateado}\nHace: ${reporte.tiempoTranscurrido}',
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: reporte.colorUrgencia,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class TacticalCarouselCard extends StatelessWidget {
  final ReportModel reporte;
  final bool isDark;

  const TacticalCarouselCard({
    super.key,
    required this.reporte,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/report-detail', extra: reporte),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: reporte.colorUrgencia, width: 6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: reporte.fotoUrl != null
                        ? Image.network(
                            reporte.fotoUrl!,
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                          )
                        : _buildFallbackIcon(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reporte.especie,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: reporte.colorUrgencia.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reporte.estadoFormateado,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: reporte.colorUrgencia,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reporte.tiempoTranscurrido,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
