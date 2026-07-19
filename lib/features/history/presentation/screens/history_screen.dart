import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/report_model.dart';
import '../providers/history_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum FiltroOrden {
  masRecientes,
  masAntiguos,
  urgenciaAlta,
  urgenciaMedia,
  urgenciaBaja,
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
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
          if (a.urgencia.toLowerCase() == 'media' &&
              b.urgencia.toLowerCase() != 'media')
            return -1;
          if (b.urgencia.toLowerCase() == 'media' &&
              a.urgencia.toLowerCase() != 'media')
            return 1;
          return 0;
        });
        break;
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId;
    final bool esVoluntario = authState.role == AppRole.voluntario;
    final historialAsync = ref.watch(misReportesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Rescates'),
        actions: [
          PopupMenuButton<FiltroOrden>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Ordenar reportes',
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
      body: historialAsync.when(
        data: (historialBruto) {
          if (historialBruto.isEmpty) {
            return const Center(child: Text('No tienes reportes registrados'));
          }
          final historialOrdenado = _ordenarReportes(historialBruto);

          // Lógica de separación de pestañas basada en el rol actual
          final reportesActivos = historialOrdenado
              .where(
                (r) =>
                    r.usuarioReportadorId == currentUserId &&
                    r.estado != 'Rescatado',
              )
              .toList();

          final reportesConcluidos = historialOrdenado
              .where(
                (r) =>
                    r.usuarioReportadorId == currentUserId &&
                    r.estado == 'Rescatado',
              )
              .toList();

          if (!esVoluntario) {
            // UI para Reportante: 2 Pestañas
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.red,
                    isScrollable: false,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.campaign_rounded),
                        text: 'Mis Alertas',
                      ),
                      Tab(
                        icon: Icon(Icons.check_circle_rounded),
                        text: 'Mis Cierres',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        reportesActivos.isEmpty
                            ? const Center(
                                child: Text('No tienes alertas activas'),
                              )
                            : _buildListaReportes(reportesActivos),
                        reportesConcluidos.isEmpty
                            ? const Center(
                                child: Text('No tienes casos concluidos'),
                              )
                            : _buildListaReportes(reportesConcluidos),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // UI para Voluntario: 3 Pestañas
          final misRescates = historialOrdenado
              .where(
                (r) =>
                    r.usuarioRescatistaId == currentUserId &&
                    r.estado == 'Rescatado',
              )
              .toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.red,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.red,
                  isScrollable: false,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.campaign_rounded),
                      text: 'Mis Alertas',
                    ),
                    Tab(
                      icon: Icon(Icons.volunteer_activism_rounded),
                      text: 'Mis Rescates',
                    ),
                    Tab(
                      icon: Icon(Icons.check_circle_rounded),
                      text: 'Mis Cierres',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      reportesActivos.isEmpty
                          ? const Center(
                              child: Text('No tienes alertas activas'),
                            )
                          : _buildListaReportes(reportesActivos),
                      misRescates.isEmpty
                          ? const Center(
                              child: Text('No has concluido rescates'),
                            )
                          : _buildListaReportes(misRescates),
                      reportesConcluidos.isEmpty
                          ? const Center(
                              child: Text('No tienes casos concluidos'),
                            )
                          : _buildListaReportes(reportesConcluidos),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildListaReportes(List<ReportModel> lista) {
    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final reporte = lista[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: reporte.fotoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
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
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.push('/report-detail', extra: reporte),
          ),
        );
      },
    );
  }
}
