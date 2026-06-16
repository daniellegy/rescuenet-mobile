import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart'; // Para peticiones HTTP

// Importaciones de Core y Auth (originales de tu código)
import '../../../../core/services/location_service.dart';
import '../../../../core/services/camera_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// NUEVAS importaciones ajustadas a tu arquitectura
import '../../../../core/network/dio_client.dart'; 
// Asumimos que ReportModel está en la carpeta history según la imagen
import '../../../history/domain/models/report_model.dart'; 
import '../../../history/presentation/screens/report_detail_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? myPosition;
  
  // Variables para guardar los reportes que vienen del servidor
  List<ReportModel> _reportesCercanos = [];
  bool _cargandoReportes = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _fetchReportes(); // Descargamos los reportes al abrir el mapa
  }

// Función para pedir los reportes al backend
  Future<void> _fetchReportes() async {
    setState(() => _cargandoReportes = true);
    try {
      final dio = ref.read(dioProvider).instance;
      final response = await dio.get('/reportes/activos'); 

      if (response.statusCode == 200) {
        // --- CÓDIGO CORREGIDO AQUÍ ---
        List<dynamic> data = [];
        
        // Si el backend manda la lista directa: [{...}, {...}]
        if (response.data is List) {
          data = response.data;
        } 
        // Si el backend lo manda envuelto: {"data": [{...}, {...}]}
        else if (response.data is Map && response.data.containsKey('data')) {
          data = response.data['data'];
        }

        List<ReportModel> reportesValidos = [];
        
        for (var jsonItem in data) {
          try {
            reportesValidos.add(ReportModel.fromJson(jsonItem));
          } catch (e) {
            debugPrint('Error de parseo en un reporte: $e');
          }
        }

        setState(() {
          _reportesCercanos = reportesValidos;
        });
        
        debugPrint('¡Éxito! Total de marcadores listos para dibujar: ${_reportesCercanos.length}');
      }
    } on DioException catch (e) {
      debugPrint('Error de red: ${e.message}');
    } catch (e) {
      debugPrint('Error general: $e');
    } finally {
      if (mounted) setState(() => _cargandoReportes = false);
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      setState(() {
        myPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _takePhotoAndNavigate() async {
    if (myPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }

    try {
      final cameraService = ref.read(cameraServiceProvider);
      final pickedFile = await cameraService.takePicture();

      if (pickedFile != null && mounted) {
        context.push(
          '/create-report',
          extra: {
            'lat': myPosition!.latitude,
            'lng': myPosition!.longitude,
            'imagePath': pickedFile.path,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  // Función auxiliar para construir todos los pines del mapa
  List<Marker> _buildMarkers() {
    List<Marker> marcadores = [];

    // 1. Por cada reporte, creamos un marcador interactivo
    for (var reporte in _reportesCercanos) {
      marcadores.add(
        Marker(
          point: LatLng(reporte.latitud, reporte.longitud),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              // Al tocar el icono, navegamos a la pantalla de detalles
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailScreen(reporte: reporte),
                ),
              );
            },
            child: const Icon(
              Icons.warning_rounded, // Icono para los reportes ("pokeparadas")
              color: Colors.orange, 
              size: 40,
            ),
          ),
        ),
      );
    }

    // 2. Al final, agregamos tu propia ubicación (para que quede dibujada por encima)
    if (myPosition != null) {
      marcadores.add(
        Marker(
          point: myPosition!,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.person_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }

    return marcadores;
  }

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Mapa de rescates'),
        backgroundColor: Colors.white.withOpacity(0.9),
        actions: [
          // Botón de recargar para buscar nuevos reportes manualmente
          if (_cargandoReportes)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: _fetchReportes,
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: myPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: myPosition!,
                initialZoom: 18,
                minZoom: 5,
                maxZoom: 25,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
                  additionalOptions: {
                    'accessToken': mapboxToken,
                    'id': 'mapbox/streets-v12',
                  },
                ),
                // Pintamos todos los marcadores (el tuyo + los reportes)
                MarkerLayer(
                  markers: _buildMarkers(), 
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _takePhotoAndNavigate,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_a_photo, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.map, color: Colors.redAccent),
              tooltip: 'Mapa',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.grey),
              tooltip: 'Mi Historial',
              onPressed: () => context.push('/history'),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.grey),
              tooltip: 'Emergencias Activas',
              onPressed: () => context.push('/active-reports'),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              tooltip: 'Configuración',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}