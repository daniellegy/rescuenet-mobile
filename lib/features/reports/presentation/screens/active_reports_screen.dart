import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../history/domain/models/report_model.dart';
import '../providers/active_reports_provider.dart';

enum FiltroOrden {
  masRecientes,
  masAntiguos,
  urgenciaAlta,
  urgenciaMedia,
  urgenciaBaja,
}

class ActiveReportsScreen extends ConsumerStatefulWidget {
  const ActiveReportsScreen({super.key});

  @override
  ConsumerState<ActiveReportsScreen> createState() =>
      _ActiveReportsScreenState();
}

class _ActiveReportsScreenState extends ConsumerState<ActiveReportsScreen> {
  FiltroOrden _ordenActual = FiltroOrden.masRecientes;

  List<ReportModel> _ordenarReportes(List<ReportModel> reportes) {
    List<ReportModel> lista = List.from(reportes);

    switch (_ordenActual) {
      case FiltroOrden.masRecientes:
        lista.sort(
          (a, b) => (b.fechaCreacion ?? DateTime.now()).compareTo(
            a.fechaCreacion ?? DateTime.now(),
          ),
        );
        break;
      case FiltroOrden.masAntiguos:
        lista.sort(
          (a, b) => (a.fechaCreacion ?? DateTime.now()).compareTo(
            b.fechaCreacion ?? DateTime.now(),
          ),
        );
        break;
      case FiltroOrden.urgenciaAlta:
        lista.sort((a, b) => b.pesoUrgencia.compareTo(a.pesoUrgencia));
        break;
      case FiltroOrden.urgenciaBaja:
        lista.sort((a, b) => a.pesoUrgencia.compareTo(b.pesoUrgencia));
        break;
      case FiltroOrden.urgenciaMedia:
        lista.sort((a, b) {
          // Si uno es 'media' y el otro no, dale prioridad absoluta al 'media'
          if (a.urgencia.toLowerCase() == 'media' &&
              b.urgencia.toLowerCase() != 'media') {
            return -1;
          }
          if (b.urgencia.toLowerCase() == 'media' &&
              a.urgencia.toLowerCase() != 'media') {
            return 1;
          }
          // CORRECCIÓN AQUÍ: Si ambos son iguales, o si NINGUNO es media, los ordena lógicamente por peso (Alta > Media > Baja)
          return b.pesoUrgencia.compareTo(a.pesoUrgencia);
        });
        break;
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final activeReportsAsync = ref.watch(activeReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergencias Activas'),
        actions: [
          PopupMenuButton<FiltroOrden>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Ordenar emergencias',
            onSelected: (FiltroOrden nuevoOrden) {
              setState(() {
                _ordenActual = nuevoOrden;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: FiltroOrden.masRecientes,
                child: Text('Más Recientes'),
              ),
              PopupMenuItem(
                value: FiltroOrden.masAntiguos,
                child: Text('Más Antiguos'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: FiltroOrden.urgenciaAlta,
                child: Text('Priorizar U. Alta'),
              ),
              PopupMenuItem(
                value: FiltroOrden.urgenciaMedia,
                child: Text('Priorizar U. Media'),
              ),
              PopupMenuItem(
                value: FiltroOrden.urgenciaBaja,
                child: Text('Priorizar U. Baja'),
              ),
            ],
          ),
        ],
      ),
      body: activeReportsAsync.when(
        data: (reportesBrutos) {
          if (reportesBrutos.isEmpty) {
            return const Center(
              child: Text(
                'No hay emergencias activas cerca de tu zona',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final reportesOrdenados = _ordenarReportes(reportesBrutos);

          return ListView.builder(
            itemCount: reportesOrdenados.length,
            itemBuilder: (context, index) {
              final reporte = reportesOrdenados[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: reporte.colorUrgencia.withValues(alpha: 0.05),
                    border: Border(
                      left: BorderSide(
                        color: reporte.colorUrgencia,
                        width: 6.0,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: reporte.fotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              reporte.fotoUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Icon(Icons.broken_image),
                                );
                              },
                            ),
                          )
                        : const SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.image_not_supported),
                          ),
                    title: Text(
                      reporte.especie,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Urgencia: ${reporte.urgencia}\nEstado: ${reporte.estadoFormateado} • ${reporte.tiempoTranscurrido}',
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: reporte.colorUrgencia,
                    ),
                    onTap: () => context.push('/report-detail', extra: reporte),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
