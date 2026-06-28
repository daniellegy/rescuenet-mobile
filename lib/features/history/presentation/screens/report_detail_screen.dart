import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/report_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/data/report_repository.dart';
import '../../../reports/presentation/providers/active_reports_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';
import '../providers/history_provider.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final ReportModel reporte;
  const ReportDetailScreen({super.key, required this.reporte});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  String _direccion = 'Buscando dirección aproximada...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _obtenerDireccionFisica();
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

  Future<void> _abrirEnMapaNativo() async {
    final lat = widget.reporte.latitud;
    final lng = widget.reporte.longitud;

    // URL universal oficial: Funciona en Android, iOS y navegadores web
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(url)) {
        // externalApplication fuerza a que se abra la app de Google Maps (o Waze) en lugar del navegador interno
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception(
          'No se encontró una aplicación de mapas en el dispositivo.',
        );
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

  Future<void> _ejecutarAccion(bool esAceptar) async {
    setState(() => _isLoading = true);
    try {
      if (esAceptar) {
        await ref
            .read(reportRepositoryProvider)
            .acceptReport(widget.reporte.id);
      } else {
        await ref
            .read(reportRepositoryProvider)
            .finalizeReport(widget.reporte.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esAceptar
                  ? 'Rescate aceptado. ¡Ve con cuidado!'
                  : 'Rescate finalizado. ¡Buen trabajo!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(activeReportsProvider);
        ref.invalidate(miRescateActivoProvider);
        ref.invalidate(misReportesProvider);

        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final esVoluntario = authState.role == AppRole.voluntario;
    final esMiRescate = widget.reporte.usuarioRescatistaId == authState.userId;
    final estaNuevo = widget.reporte.estado == 'Nuevo';
    final estaEnProceso = widget.reporte.estado == 'En_Proceso';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Emergencia'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.reporte.fotoUrl != null)
              Image.network(
                widget.reporte.fotoUrl!,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 250,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.reporte.especie,
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
                          color: widget.reporte.colorUrgencia.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.reporte.colorUrgencia,
                          ),
                        ),
                        child: Text(
                          widget.reporte.estadoFormateado.toUpperCase(),
                          style: TextStyle(
                            color: widget.reporte.colorUrgencia,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // FILA DE FECHA/TIEMPO TRANSCURRIDO
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reportado ${widget.reporte.tiempoTranscurrido}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ubicación aproximada:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // CONTENEDOR AZUL PARA LA UBICACIÓN CON FORMATO BOTÓN
                  Material(
                    color: Colors.blue.shade50,
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
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.blue.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _direccion,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.navigation_rounded,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),

                  // SECCIÓN DE NOMBRES
                  const Text(
                    'Personas Involucradas:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildPersonRow(
                    Icons.person_pin_circle_rounded,
                    'Reportado por',
                    widget.reporte.nombreReportador ??
                        'Ciudadano (Validando...)',
                  ),
                  if (widget.reporte.nombreRescatista != null &&
                      widget.reporte.nombreRescatista!.isNotEmpty)
                    _buildPersonRow(
                      Icons.volunteer_activism_rounded,
                      widget.reporte.estado == 'Rescatado'
                          ? 'Rescate completado por'
                          : 'Rescatista asignado',
                      widget.reporte.nombreRescatista!,
                    ),
                  const Divider(height: 32),
                  _buildDetailRow(
                    Icons.palette,
                    'Color',
                    widget.reporte.colorDominante,
                  ),
                  _buildDetailRow(Icons.pets, 'Raza', widget.reporte.razaAprox),
                  _buildDetailRow(
                    Icons.transgender,
                    'Sexo',
                    widget.reporte.sexo,
                  ),
                  _buildDetailRow(
                    Icons.cake,
                    'Edad Aprox.',
                    widget.reporte.edadAprox,
                  ),
                  _buildDetailRow(
                    Icons.straighten,
                    'Tamaño',
                    widget.reporte.tamano,
                  ),
                  _buildDetailRow(
                    Icons.mood_bad,
                    'Agresividad',
                    '${widget.reporte.agresividad}/10',
                  ),
                  _buildDetailRow(
                    Icons.track_changes, // Icono de radar/mira
                    'Radio de Búsqueda',
                    '${widget.reporte.radio ?? 500} metros',
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Señas particulares:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.reporte.caracteristicasEspeciales,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notas adicionales:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.reporte.notasAdicionales,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  if (esVoluntario && estaNuevo) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.push('/search-radar', extra: widget.reporte);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ), // Todo el ancho disponible
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.radar_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Iniciar Ruta de Búsqueda',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
    if (!esVoluntario) return const SizedBox.shrink();

    if (estaNuevo) {
      return _bottomButtonContainer(
        'Aceptar Rescate',
        Colors.red,
        () => _ejecutarAccion(true),
      );
    } else if (estaEnProceso && esMiRescate) {
      return _bottomButtonContainer(
        'Finalizar Rescate',
        Colors.green,
        () => _ejecutarAccion(false),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _bottomButtonContainer(
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FilledButton(
          onPressed: _isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildPersonRow(IconData icon, String role, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Text(
            '$role: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
