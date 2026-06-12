import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/report_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

  // 1. Obtener la calle usando lat y lng
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
              'Ubicación GPS fijada. Toca para navegar en el mapa.',
        );
    }
  }

  // 2. Abrir Waze, Google Maps o Apple Maps nativo
  Future<void> _abrirNavegacionGPS() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.reporte.latitud},${widget.reporte.longitud}',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de mapas'),
          ),
        );
    }
  }

  // 3. Conexión a la ruta PUT para aceptar el reporte
  Future<void> _aceptarCaso() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider).instance;
      await dio.put('/reportes/${widget.reporte.id}/aceptar');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Rescate aceptado exitosamente!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al aceptar el caso de rescate.')),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolActual = ref.watch(authProvider).role;
    final puedeAceptar =
        rolActual == AppRole.voluntario && widget.reporte.estado == 'Nuevo';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalles del Caso'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reporte.fotoUrl != null)
              Image.network(
                widget.reporte.fotoUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Widget Navegable
                  InkWell(
                    onTap: _abrirNavegacionGPS,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.directions,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ir a la ubicación (Toca para navegar)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _direccion,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Información General
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estado Actual: ${widget.reporte.estado}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Agresividad: Nivel ${widget.reporte.agresividad} / 10',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Especie: ${widget.reporte.especie} • Sexo: ${widget.reporte.sexo}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 24),

                  const Text(
                    'Características Especiales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.reporte.caracteristicasEspeciales,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A4A4A),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Notas Adicionales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.reporte.notasAdicionales,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A4A4A),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Mostrar Botón solo si el Estado es "Nuevo" y el usuario es Voluntario
      bottomNavigationBar: puedeAceptar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FilledButton(
                  onPressed: _isLoading ? null : _aceptarCaso,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Aceptar Rescate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
