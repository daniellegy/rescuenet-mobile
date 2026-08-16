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
  String _filtroUrgencia = 'todos';
  String _filtroEspecie = 'todos';

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
        lista.sort((a, b) {
          int cmp = b.pesoUrgencia.compareTo(a.pesoUrgencia);
          if (cmp == 0) {
            return (b.fechaCreacion ?? DateTime.now()).compareTo(
              a.fechaCreacion ?? DateTime.now(),
            );
          }
          return cmp;
        });
        break;
      case FiltroOrden.urgenciaBaja:
        lista.sort((a, b) {
          int cmp = a.pesoUrgencia.compareTo(b.pesoUrgencia);
          if (cmp == 0) {
            return (b.fechaCreacion ?? DateTime.now()).compareTo(
              a.fechaCreacion ?? DateTime.now(),
            );
          }
          return cmp;
        });
        break;
      case FiltroOrden.urgenciaMedia:
        lista.sort((a, b) {
          if (a.urgencia.toLowerCase() == 'media' &&
              b.urgencia.toLowerCase() != 'media') {
            return -1;
          }
          if (b.urgencia.toLowerCase() == 'media' &&
              a.urgencia.toLowerCase() != 'media') {
            return 1;
          }
          int cmp = b.pesoUrgencia.compareTo(a.pesoUrgencia);
          if (cmp == 0) {
            return (b.fechaCreacion ?? DateTime.now()).compareTo(
              a.fechaCreacion ?? DateTime.now(),
            );
          }
          return cmp;
        });
        break;
    }
    return lista;
  }

  void _mostrarMenuOpciones(
    String titulo,
    List<String> opciones,
    Function(String) onSeleccionado,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filtrar por $titulo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...opciones.map(
              (opc) => ListTile(
                title: Text(opc.toUpperCase(), textAlign: TextAlign.center),
                onTap: () {
                  onSeleccionado(opc);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.blueAccent
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isSelected
                  ? Colors.blueAccent
                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
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

          final filtrados = historialBruto.where((r) {
            if (_filtroUrgencia != 'todos' &&
                r.urgencia.toLowerCase() != _filtroUrgencia) {
              return false;
            }
            final esp = (r.especie ?? '').toLowerCase();
            if (_filtroEspecie == 'perros' && !esp.contains('perro')) {
              return false;
            }
            if (_filtroEspecie == 'gatos' && !esp.contains('gato')) {
              return false;
            }
            if (_filtroEspecie == 'silvestres' &&
                !(esp.contains('silvestre') || esp.contains('mapache'))) {
              return false;
            }
            return true;
          }).toList();

          final historialOrdenado = _ordenarReportes(filtrados);

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

          final filterBar = Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('Urgencia', _filtroUrgencia != 'todos', () {
                    _mostrarMenuOpciones('Urgencia', [
                      'todos',
                      'alta',
                      'media',
                      'baja',
                    ], (val) => setState(() => _filtroUrgencia = val));
                  }),
                  _buildFilterChip('Especie', _filtroEspecie != 'todos', () {
                    _mostrarMenuOpciones('Especie', [
                      'todos',
                      'perros',
                      'gatos',
                      'silvestres',
                    ], (val) => setState(() => _filtroEspecie = val));
                  }),
                ],
              ),
            ),
          );

          if (!esVoluntario) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  filterBar,
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
                filterBar,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final reporte = lista[index];
        return Card(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
