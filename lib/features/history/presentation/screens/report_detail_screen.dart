import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../reports/domain/models/report_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/data/report_repository.dart';
import '../../../map/presentation/providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/active_reports_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';
import '../providers/history_provider.dart';
import '../../../reports/presentation/providers/rescue_stepper_provider.dart';
import '../../../reports/presentation/widgets/canal_chat_sheet.dart';
import '../../../../core/services/location_service.dart';
import '../widgets/report_detail_components.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final ReportModel reporte;
  const ReportDetailScreen({super.key, required this.reporte});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  String _direccion = 'Buscando dirección aproximada...';
  bool _isLoading = false;
  bool _canalCerradoLocalmente = false;
  ReportModel? _reporteLocal;
  Position? _userPos;

  // Actualizado a Switch Expression (Dart 3+)
  Color _obtenerColorPorEstado(String estado) {
    return switch (estado.toLowerCase()) {
      'nuevo' => const Color(0xFF0288D1),
      'en_proceso' || 'en proceso' => const Color(0xFFF57C00),
      'rescatado' => const Color(0xFF388E3C),
      _ => Colors.grey,
    };
  }

  @override
  void initState() {
    super.initState();
    _obtenerDireccionFisica();
    _obtenerUbicacionUsuario();
  }

  Future<void> _obtenerUbicacionUsuario() async {
    try {
      final pos = await ref
          .read(locationServiceProvider)
          .getCurrentPosition(requestPermission: false);
      if (mounted) {
        setState(() => _userPos = pos);
      }
    } catch (_) {}
  }

  Future<bool> _hayMensajesSinLeer() async {
    try {
      final mensajes = await ref
          .read(reportRepositoryProvider)
          .obtenerMensajesCanal(widget.reporte.id);
      if (mensajes.isEmpty) {
        return false;
      }
      final ultimoId = mensajes.last['id'] as int;
      final prefs = await SharedPreferences.getInstance();
      final leidoId = prefs.getInt('canal_leido_${widget.reporte.id}') ?? 0;
      return ultimoId > leidoId;
    } catch (_) {
      return false;
    }
  }

  Future<void> _abrirEnMapaNativo() async {
    final double lat = widget.reporte.latitud;
    final double lng = widget.reporte.longitud;
    final Uri url = Uri.parse('https://maps.google.com/?q=$lat,$lng');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se encontró aplicación de mapas.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _intentarAceptar() async {
    Position? currentPos = _userPos;

    if (currentPos == null) {
      setState(() => _isLoading = true);
      try {
        currentPos = await ref
            .read(locationServiceProvider)
            .getCurrentPosition(requestPermission: false);
        if (mounted) {
          setState(() => _userPos = currentPos);
        }
      } catch (_) {}

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (currentPos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener tu ubicación para aceptar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final distance = Geolocator.distanceBetween(
      currentPos.latitude,
      currentPos.longitude,
      widget.reporte.latitud,
      widget.reporte.longitud,
    );

    if (distance > 100000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Estás muy lejos de esta ciudad para aceptar el rescate.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    _ejecutarAceptar();
  }

  Future<void> _ejecutarAceptar() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(reportRepositoryProvider).acceptReport(widget.reporte.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rescate aceptado. ¡Ve con cuidado!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(activeReportsProvider);
        ref.invalidate(miRescateActivoProvider);
        ref.invalidate(misReportesProvider);
        ref.invalidate(reportesActivosMapaProvider);
        context.go('/map');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmarYAbortar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Seguro de abortar?'),
        content: const Text(
          'El reporte volverá a estar activo para que otro voluntario pueda tomarlo y tu progreso en el asistente se perderá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, mantener'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, abortar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(reportRepositoryProvider).abortReport(widget.reporte.id);
        ref.read(rescueStepperProvider.notifier).reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rescate abortado.'),
              backgroundColor: Colors.orange,
            ),
          );
          ref.invalidate(activeReportsProvider);
          ref.invalidate(miRescateActivoProvider);
          ref.invalidate(misReportesProvider);
          ref.invalidate(reportesActivosMapaProvider);
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _abrirCanalComunicacion() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => CanalChatSheet(
        reporteId: widget.reporte.id,
        onCanalCerrado: () => setState(() => _canalCerradoLocalmente = true),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _obtenerDireccionFisica() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.reporte.latitud,
        widget.reporte.longitud,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        if (mounted) {
          setState(
            () => _direccion =
                '${place.street}, ${place.subLocality}, ${place.locality}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _direccion =
              'Coordenadas: ${widget.reporte.latitud}, ${widget.reporte.longitud}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final esVoluntario = authState.role == AppRole.voluntario;
    final esMiRescate = widget.reporte.usuarioRescatistaId == authState.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _reporteLocal ??= widget.reporte;

    if (esMiRescate) {
      final miRescateAsync = ref.watch(miRescateActivoProvider);
      miRescateAsync.whenData((rescateBackend) {
        if (rescateBackend != null && rescateBackend.id == widget.reporte.id) {
          _reporteLocal = rescateBackend;
        }
      });
    }

    ReportModel reporteActual = _reporteLocal!;
    final esReportador = reporteActual.usuarioReportadorId == authState.userId;
    final estaNuevo = reporteActual.estado == 'Nuevo';
    final estaEnProceso = reporteActual.estado == 'En_Proceso';

    List<String> photos = [];
    if (reporteActual.fotoUrl != null) {
      photos.add(reporteActual.fotoUrl!);
    }
    if (reporteActual.fotoEvidenciaUrl != null) {
      photos.add(reporteActual.fotoEvidenciaUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Emergencia'),
        actions: [
          if (reporteActual.canalComunicacionHabilitado &&
              reporteActual.canalComunicacionEstado == 'activo' &&
              !_canalCerradoLocalmente)
            FutureBuilder<bool>(
              future: _hayMensajesSinLeer(),
              builder: (context, snapshot) {
                final hayNuevos = snapshot.data ?? false;
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'Canal de comunicación',
                      onPressed: _abrirCanalComunicacion,
                    ),
                    if (hayNuevos)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportImageCarousel(photos: photos), // Componente extraído
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        reporteActual.especie,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _obtenerColorPorEstado(
                            reporteActual.estado,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _obtenerColorPorEstado(reporteActual.estado),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          reporteActual.estadoFormateado.toUpperCase(),
                          style: TextStyle(
                            color: _obtenerColorPorEstado(reporteActual.estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!estaNuevo) ...[
                    Card(
                      elevation: 0,
                      color: isDark
                          ? Colors.blueGrey.shade900.withValues(alpha: 0.5)
                          : Colors.blueGrey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? Colors.blueGrey.shade700
                              : Colors.blueGrey.shade200,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seguimiento en Tiempo Real',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark
                                    ? Colors.blueGrey.shade300
                                    : Colors.blueGrey,
                              ),
                            ),
                            const Divider(),
                            ReportPhaseRow(
                              icon: Icons.visibility,
                              label: 'Avistamiento',
                              value: reporteActual.animalAvistado == true
                                  ? 'Voluntario en zona (Avistado)'
                                  : (reporteActual.animalAvistado == false
                                        ? 'No encontrado en área'
                                        : 'En camino / Pendiente'),
                            ),
                            ReportPhaseRow(
                              icon: Icons.directions_car,
                              label: 'Traslado a',
                              value: reporteActual.lugarTraslado ?? 'Pendiente',
                            ),
                            ReportPhaseRow(
                              icon: Icons.house,
                              label: 'Destino Final',
                              value: reporteActual.destinoFinal ?? 'Pendiente',
                            ),
                            ReportPhaseRow(
                              icon: Icons.attach_money,
                              label: 'Costo',
                              value: reporteActual.costoRescate != null
                                  ? '\$${reporteActual.costoRescate} MXN'
                                  : 'Calculando al finalizar...',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Material(
                    color: isDark
                        ? Colors.blue.shade900.withValues(alpha: 0.2)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _abrirEnMapaNativo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? Colors.blue.shade800
                                : Colors.blue.shade200,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Presione aquí para ir al lugar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _direccion,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.blue.shade100
                                          : Colors.blue.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.navigation_rounded,
                              color: isDark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  ReportPersonRow(
                    role: 'Reportado por',
                    name: reporteActual.nombreReportador ?? 'Ciudadano',
                    fotoUrl: reporteActual.fotoReportador,
                    userId: reporteActual.usuarioReportadorId,
                  ),
                  if (reporteActual.nombreRescatista != null)
                    ReportPersonRow(
                      role: reporteActual.estado == 'Rescatado'
                          ? 'Completado por'
                          : 'Rescatista',
                      name: reporteActual.nombreRescatista!,
                      fotoUrl: reporteActual.fotoRescatista,
                      userId: reporteActual.usuarioRescatistaId,
                      isRescatista: true,
                    ),
                  const Divider(height: 32),
                  ReportDetailRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Nivel de Urgencia',
                    value: reporteActual.urgencia.toUpperCase(),
                  ),
                  ReportDetailRow(
                    icon: Icons.explore_outlined,
                    label: 'Referencias',
                    value: reporteActual.referencias ?? 'Sin referencias',
                  ),
                  ReportDetailRow(
                    icon: Icons.palette,
                    label: 'Color',
                    value: reporteActual.colorDominante,
                  ),
                  ReportDetailRow(
                    icon: Icons.pets,
                    label: 'Raza',
                    value: reporteActual.razaAprox,
                  ),
                  ReportDetailRow(
                    icon: Icons.transgender,
                    label: 'Sexo',
                    value: reporteActual.sexo,
                  ),
                  ReportDetailRow(
                    icon: Icons.cake,
                    label: 'Edad Aprox.',
                    value: reporteActual.edadAprox,
                  ),
                  ReportDetailRow(
                    icon: Icons.straighten,
                    label: 'Tamaño',
                    value: reporteActual.tamano,
                  ),
                  ReportDetailRow(
                    icon: Icons.mood_bad,
                    label: 'Agresividad',
                    value: '${reporteActual.agresividad}/10',
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Notas adicionales:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reporteActual.notasAdicionales.isNotEmpty &&
                            reporteActual.notasAdicionales != 'Ninguna'
                        ? reporteActual.notasAdicionales
                        : (reporteActual.caracteristicasEspeciales.isNotEmpty
                              ? reporteActual.caracteristicasEspeciales
                              : 'Sin notas adicionales.'),
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  if (reporteActual.conclusion != null &&
                      reporteActual.conclusion!.isNotEmpty) ...[
                    const Divider(height: 32),
                    const Text(
                      'Conclusión del rescate:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reporteActual.conclusion!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                  if (!reporteActual.canalComunicacionHabilitado &&
                      esReportador &&
                      reporteActual.estado != 'Resuelto' &&
                      reporteActual.estado != 'Cancelado') ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Activar canal de comunicación'),
                            content: const Text(
                              'Esto habilitará el chat con el voluntario asignado a tu caso.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Activar'),
                              ),
                            ],
                          ),
                        );

                        if (confirmar != true) {
                          return;
                        }

                        try {
                          await ref
                              .read(reportRepositoryProvider)
                              .activarCanalManual(reporteActual.id);
                          setState(() {
                            _reporteLocal = reporteActual.copyWithCanal(
                              canalComunicacionHabilitado: true,
                              canalComunicacionEstado:
                                  reporteActual.estado == 'En_Proceso'
                                  ? 'activo'
                                  : 'inactivo',
                            );
                          });
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.green.shade700,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.green.shade700,
                      ),
                      label: Text(
                        'Activar canal de comunicación',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (esVoluntario && estaNuevo) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/search-radar', extra: reporteActual),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(
                        Icons.radar_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Mostrar radio de búsqueda',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(
        esVoluntario,
        estaNuevo,
        estaEnProceso,
        esMiRescate,
      ),
    );
  }

  Widget? _buildBottomBar(
    bool esVoluntario,
    bool estaNuevo,
    bool estaEnProceso,
    bool esMiRescate,
  ) {
    if (!esVoluntario) {
      return const SizedBox.shrink();
    }

    if (estaNuevo) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FilledButton(
            onPressed: _isLoading ? null : _intentarAceptar,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Aceptar Rescate', style: TextStyle(fontSize: 16)),
          ),
        ),
      );
    } else if (estaEnProceso && esMiRescate) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: FilledButton(
                  onPressed: _isLoading ? null : _confirmarYAbortar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.push(
                          '/search-radar',
                          extra: widget.reporte,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => context.push(
                          '/rescue-stepper',
                          extra: widget.reporte,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.linear_scale_rounded),
                  label: const Text(
                    'Iniciar Rescate',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
