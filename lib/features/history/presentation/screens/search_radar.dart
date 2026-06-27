import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/models/report_model.dart'; // Verifica que apunte correctamente a tu modelo

class SearchRadarScreen extends StatefulWidget {
  final ReportModel reporte;
  const SearchRadarScreen({super.key, required this.reporte});

  @override
  State<SearchRadarScreen> createState() => _SearchRadarScreenState();
}

class _SearchRadarScreenState extends State<SearchRadarScreen> {
  late final MapController _mapController;
  LatLng? _currentPosition;
  double _distanciaEnMetros = 0.0;
  bool _estaDentroDelRadar = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _iniciarSeguimientoGPS();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSeguimientoGPS() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, 
      ),
    ).listen((Position position) {
      if (mounted) {
        final userLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = userLatLng;
        });
        _calcularMetricas(position);
      }
    });
  }

  void _calcularMetricas(Position posicionUsuario) {
    final double distancia = Geolocator.distanceBetween(
      posicionUsuario.latitude,
      posicionUsuario.longitude,
      widget.reporte.latitud,
      widget.reporte.longitud,
    );

    // Ahora lee el radio del reporte. Si es null, usa 500 por defecto.
    final double radioReporte = (widget.reporte.radio ?? 500).toDouble(); 

    setState(() {
      _distanciaEnMetros = distancia;
      _estaDentroDelRadar = distancia <= radioReporte;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
    final targetReport = LatLng(widget.reporte.latitud, widget.reporte.longitud);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Búsqueda (Radar)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: targetReport,
              initialZoom: 16.0,
              minZoom: 5.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
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
              
              // POLYLINES CORREGIDA: Línea guía continua sólida para evitar fallos de versión
              PolylineLayer(
                polylines: [
                  if (_currentPosition != null && !_estaDentroDelRadar)
                    Polyline(
                      points: [_currentPosition!, targetReport],
                      color: Colors.blue.shade800,
                      strokeWidth: 4.0,
                    ),
                ],
              ),

              CircleLayer(
                circles: [
                  CircleMarker(
                    point: targetReport,
                    radius: (widget.reporte.radio ?? 500).toDouble(), 
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue.shade700,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: targetReport,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.reporte.colorUrgencia.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.reporte.colorUrgencia, width: 2.5),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: widget.reporte.colorUrgencia,
                        size: 26,
                      ),
                    ),
                  ),
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.person_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            bottom: 140,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
              elevation: 4,
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(_currentPosition!, 18);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // =======================================================
          // INTERFAZ INFERIOR CONTEXTUAL CORREGIDA (SIn ERRORES DE CONST)
          // =======================================================
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: _estaDentroDelRadar ? Colors.green.shade50 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: _estaDentroDelRadar
                    ? Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 32),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '¡Estás en la zona!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 17, 
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Te encuentras dentro del radar de localización del animal.',
                                  style: TextStyle(fontSize: 13, color: Colors.black87), // CORREGIDO AQUÍ
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.navigation_rounded, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                'Distancia al objetivo:',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          ),
                          Text(
                            _distanciaEnMetros > 1000
                                ? '${(_distanciaEnMetros / 1000).toStringAsFixed(2)} km'
                                : '${_distanciaEnMetros.round()} m',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 18, 
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}