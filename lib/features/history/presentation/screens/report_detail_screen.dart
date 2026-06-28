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
import '../../../reports/presentation/providers/rescue_stepper_provider.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final ReportModel reporte;
  const ReportDetailScreen({super.key, required this.reporte});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  String _direccion = 'Buscando dirección aproximada...';
  bool _isLoading = false;
  int _currentPhotoIndex = 0; // Para el Slider

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
        if (mounted)
          setState(
            () => _direccion =
                '${place.street}, ${place.subLocality}, ${place.locality}',
          );
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _direccion =
              'Coordenadas: ${widget.reporte.latitud}, ${widget.reporte.longitud}',
        );
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
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
        context.go('/map'); // Redirige al mapa en lugar de atras
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmarYAbortar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Estás seguro de abortar?'),
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
        ref
            .read(rescueStepperProvider.notifier)
            .reset(); // Limpia estado global del stepper
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
          context.pop();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final esVoluntario = authState.role == AppRole.voluntario;
    final esMiRescate = widget.reporte.usuarioRescatistaId == authState.userId;
    final estaNuevo = widget.reporte.estado == 'Nuevo';
    final estaEnProceso = widget.reporte.estado == 'En_Proceso';

    List<String> photos = [];
    if (widget.reporte.fotoUrl != null) photos.add(widget.reporte.fotoUrl!);
    if (widget.reporte.fotoEvidenciaUrl != null)
      photos.add(widget.reporte.fotoEvidenciaUrl!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Emergencia'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (photos.isNotEmpty)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      itemCount: photos.length,
                      onPageChanged: (index) =>
                          setState(() => _currentPhotoIndex = index),
                      itemBuilder: (context, index) => Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (photos.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          photos.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPhotoIndex == index
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                          color: widget.reporte.colorUrgencia.withValues(
                            alpha: 0.2,
                          ),
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
                  const SizedBox(height: 16),

                  // SECCIÓN DINÁMICA DE SEGUIMIENTO (Req 8)
                  if (!estaNuevo) ...[
                    Card(
                      elevation: 0,
                      color: Colors.blueGrey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blueGrey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seguimiento en Tiempo Real',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const Divider(),
                            _buildPhaseRow(
                              Icons.visibility,
                              'Avistamiento',
                              widget.reporte.animalAvistado == true
                                  ? 'Voluntario en zona (Avistado)'
                                  : (widget.reporte.animalAvistado == false
                                        ? 'No encontrado en área'
                                        : 'En camino / Pendiente'),
                            ),
                            _buildPhaseRow(
                              Icons.directions_car,
                              'Traslado a',
                              widget.reporte.lugarTraslado ?? 'Pendiente',
                            ),
                            _buildPhaseRow(
                              Icons.house,
                              'Destino Final',
                              widget.reporte.destinoFinal ?? 'Pendiente',
                            ),
                            _buildPhaseRow(
                              Icons.attach_money,
                              'Costo',
                              widget.reporte.costoRescate != null
                                  ? '\$${widget.reporte.costoRescate} MXN'
                                  : 'Calculando al finalizar...',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                  _buildPersonRow(
                    Icons.person_pin_circle_rounded,
                    'Reportado por',
                    widget.reporte.nombreReportador ?? 'Ciudadano',
                  ),
                  if (widget.reporte.nombreRescatista != null)
                    _buildPersonRow(
                      Icons.volunteer_activism_rounded,
                      widget.reporte.estado == 'Rescatado'
                          ? 'Completado por'
                          : 'Rescatista',
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
                  const Divider(height: 32),
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
                      onPressed: () =>
                          context.push('/search-radar', extra: widget.reporte),
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
                        'Iniciar Ruta de Búsqueda',
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
    if (!esVoluntario) return const SizedBox.shrink();

    if (estaNuevo) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FilledButton(
            onPressed: _isLoading ? null : _ejecutarAceptar,
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
                flex: 2,
                child: FilledButton(
                  onPressed: _isLoading ? null : _confirmarYAbortar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Abortar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => context.push(
                          '/rescue-stepper',
                          extra: widget.reporte,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.linear_scale_rounded),
                  label: const Text('Fases del Rescate'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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

  Widget _buildPhaseRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey.shade400),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
