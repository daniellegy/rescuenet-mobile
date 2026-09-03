import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/active_reports_provider.dart';
import 'tactical_report_cards.dart';

class LocalReportsTab extends ConsumerStatefulWidget {
  final bool isDark;
  const LocalReportsTab({super.key, required this.isDark});

  @override
  ConsumerState<LocalReportsTab> createState() => _LocalReportsTabState();
}

class _LocalReportsTabState extends ConsumerState<LocalReportsTab> {
  String _filtroUrgencia = 'todos';
  String _filtroEspecie = 'todos';
  double _filtroDistancia = 999;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionUsuario();
  }

  Future<void> _obtenerUbicacionUsuario() async {
    try {
      final pos =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (_) {}
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
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
            color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
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
                'FILTRAR POR $titulo'.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Archivo Black',
                  fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final activeReportsAsync = ref.watch(activeReportsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                _buildFilterChip(
                  _filtroDistancia == 999
                      ? 'Distancia'
                      : '${_filtroDistancia.toInt()} km',
                  _filtroDistancia != 999,
                  () {
                    _mostrarMenuOpciones(
                      'Distancia',
                      ['3 km', '5 km', '10 km', '15 km', 'Todos'],
                      (val) {
                        setState(() {
                          if (val == 'Todos') {
                            _filtroDistancia = 999.0;
                          } else {
                            _filtroDistancia = double.parse(
                              val.replaceAll(' km', ''),
                            );
                          }
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: activeReportsAsync.when(
            data: (reportesBrutos) {
              final filtrados = reportesBrutos.where((r) {
                if (_filtroUrgencia != 'todos' &&
                    r.urgencia.toLowerCase() != _filtroUrgencia) {
                  return false;
                }
                final esp = r.especie.toLowerCase();
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
                if (_filtroDistancia != 999 && _userPosition != null) {
                  final dist = Geolocator.distanceBetween(
                    _userPosition!.latitude,
                    _userPosition!.longitude,
                    r.latitud,
                    r.longitud,
                  );
                  if (dist > _filtroDistancia * 1000) {
                    return false;
                  }
                }
                return true;
              }).toList();

              if (filtrados.isEmpty) {
                return const Center(
                  child: Text('No se encontraron reportes con estos filtros.'),
                );
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filtrados.length,
                itemBuilder: (context, index) => TacticalListCard(
                  reporte: filtrados[index],
                  isDark: widget.isDark,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
