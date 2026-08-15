import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../history/domain/models/report_model.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/active_reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // Estados para filtros de Reportes Locales
  String _filtroUrgencia = 'todos';
  String _filtroEspecie = 'todos';
  double _filtroDistancia = 999;
  Position? _userPosition;

  // Estados para expandir carruseles en "Mis Reportes"
  bool _verMasAlertas = false;
  bool _verMasRescates = false;
  bool _verMasConcluidos = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionUsuario();
  }

  Future<void> _obtenerUbicacionUsuario() async {
    try {
      final pos = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (_) {}
  }

  // Lógica para cerrar al deslizar hacia abajo
  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity! > 300) {
      // Si la velocidad hacia abajo es fuerte, cerramos el modal
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: screenHeight * 0.96,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 25,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                // 1. HEADER ARRASTRABLE
                GestureDetector(
                  onVerticalDragEnd: _onVerticalDragEnd,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 16.0, right: 16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'REPORTES',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                                ),
                                onPressed: () => context.pop(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. TABS (REPORTES LOCALES COMO PRINCIPAL)
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    initialIndex: 0, // Automáticamente carga el índice 0
                    child: Column(
                      children: [
                        const TabBar(
                          indicatorColor: Colors.blueAccent,
                          labelColor: Colors.blueAccent,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          tabs: [
                            Tab(text: 'REPORTES LOCALES'),
                            Tab(text: 'MIS REPORTES'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildReportesLocalesTab(isDark),
                              _buildMisReportesTab(isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PESTAÑA 1: REPORTES LOCALES
  // ===========================================================================
  Widget _buildReportesLocalesTab(bool isDark) {
    final activeReportsAsync = ref.watch(activeReportsProvider);

    return Column(
      children: [
        // FILTROS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Urgencia', _filtroUrgencia != 'todos', () {
                  _mostrarMenuOpciones('Urgencia', ['todos', 'alta', 'media', 'baja'], (val) => setState(() => _filtroUrgencia = val));
                }),
                _buildFilterChip('Especie', _filtroEspecie != 'todos', () {
                  _mostrarMenuOpciones('Especie', ['todos', 'perros', 'gatos', 'silvestres'], (val) => setState(() => _filtroEspecie = val));
                }),
                _buildFilterChip(_filtroDistancia == 999 ? 'Distancia' : '${_filtroDistancia.toInt()} km', _filtroDistancia != 999, () {
                  _mostrarMenuOpciones('Distancia', ['3', '5', '10', '15', 'todos'], (val) {
                    setState(() => _filtroDistancia = val == 'todos' ? 999.0 : double.parse(val));
                  });
                }),
              ],
            ),
          ),
        ),
        // LISTA
        Expanded(
          child: activeReportsAsync.when(
            data: (reportesBrutos) {
              final filtrados = reportesBrutos.where((r) {
                // Filtro Urgencia
                if (_filtroUrgencia != 'todos' && r.urgencia.toLowerCase() != _filtroUrgencia) return false;
                // Filtro Especie
                final esp = (r.especie ?? '').toLowerCase();
                if (_filtroEspecie == 'perros' && !esp.contains('perro')) return false;
                if (_filtroEspecie == 'gatos' && !esp.contains('gato')) return false;
                if (_filtroEspecie == 'silvestres' && !(esp.contains('silvestre') || esp.contains('mapache'))) return false;
                // Filtro Distancia
                if (_filtroDistancia != 999 && _userPosition != null) {
                  final dist = Geolocator.distanceBetween(_userPosition!.latitude, _userPosition!.longitude, r.latitud, r.longitud);
                  if (dist > _filtroDistancia * 1000) return false;
                }
                return true;
              }).toList();

              if (filtrados.isEmpty) {
                return const Center(child: Text('No se encontraron reportes con estos filtros.'));
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filtrados.length,
                itemBuilder: (context, index) => _buildTacticalListCard(filtrados[index], isDark),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PESTAÑA 2: MIS REPORTES
  // ===========================================================================
  Widget _buildMisReportesTab(bool isDark) {
    final historialAsync = ref.watch(misReportesProvider);
    final currentUserId = ref.watch(authProvider).userId;

    return historialAsync.when(
      data: (reportes) {
        final alertasActivas = reportes.where((r) => r.usuarioReportadorId == currentUserId && r.estado != 'Rescatado').toList();
        final rescatesActivos = reportes.where((r) => r.usuarioRescatistaId == currentUserId && r.estado != 'Rescatado').toList();
        final concluidos = reportes.where((r) => r.estado == 'Rescatado').toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportSection('Alertas Activas', alertasActivas, isDark, Icons.campaign_rounded, _verMasAlertas, () => setState(() => _verMasAlertas = !_verMasAlertas)),
              const SizedBox(height: 24),
              _buildReportSection('Rescates Activos', rescatesActivos, isDark, Icons.health_and_safety_rounded, _verMasRescates, () => setState(() => _verMasRescates = !_verMasRescates)),
              const SizedBox(height: 24),
              _buildReportSection('Concluido', concluidos, isDark, Icons.check_circle_outline_rounded, _verMasConcluidos, () => setState(() => _verMasConcluidos = !_verMasConcluidos)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar tu historial')),
    );
  }

  Widget _buildReportSection(String title, List<ReportModel> items, bool isDark, IconData icon, bool showAll, VoidCallback onToggle) {
    if (items.isEmpty) return const SizedBox.shrink();

    final displayItems = showAll ? items : items.take(4).toList();
    final bool canExpand = items.length > 4;

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
                  Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              if (canExpand)
                TextButton(
                  onPressed: onToggle,
                  child: Text(showAll ? 'Ver menos' : 'Ver más', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        if (showAll)
          // MODO LISTA VERTICAL
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) => _buildTacticalListCard(displayItems[index], isDark),
          )
        else
          // MODO CARRUSEL (Máx 4)
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(left: 20.0, right: index == displayItems.length - 1 ? 20.0 : 0),
                  child: _buildTacticalCarouselCard(displayItems[index], isDark),
                );
              },
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // COMPONENTES UI COMPARTIDOS
  // ===========================================================================
  
  // Chip de filtros para la parte superior
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.blueAccent : Colors.grey.shade600)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isSelected ? Colors.blueAccent : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  // BottomSheet simple para las opciones de los filtros
  void _mostrarMenuOpciones(String titulo, List<String> opciones, Function(String) onSeleccionado) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('Filtrar por $titulo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ...opciones.map((opc) => ListTile(
              title: Text(opc.toUpperCase(), textAlign: TextAlign.center),
              onTap: () {
                onSeleccionado(opc);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  // Tarjeta Horizontal para Carruseles
  Widget _buildTacticalCarouselCard(ReportModel reporte, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/report-detail', extra: reporte),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: reporte.colorUrgencia, width: 6)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
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
                        ? Image.network(reporte.fotoUrl!, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (_,__,___) => _fallbackIcon())
                        : _fallbackIcon(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reporte.especie, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: reporte.colorUrgencia.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(reporte.estadoFormateado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: reporte.colorUrgencia)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(reporte.tiempoTranscurrido, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta Vertical para Listas ("Ver Más" y Reportes Locales)
  Widget _buildTacticalListCard(ReportModel reporte, bool isDark) {
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
            border: Border(left: BorderSide(color: reporte.colorUrgencia, width: 6)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: reporte.fotoUrl != null
                  ? Image.network(reporte.fotoUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => _fallbackIcon())
                  : _fallbackIcon(),
            ),
            title: Text(reporte.especie, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Estado: ${reporte.estadoFormateado}\nHace: ${reporte.tiempoTranscurrido}'),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: reporte.colorUrgencia, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() => Container(width: 45, height: 45, color: Colors.grey.shade300, child: const Icon(Icons.pets, color: Colors.grey));
}