import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../reports/domain/models/report_model.dart';

class SearchRadarScreen extends StatefulWidget {
  final ReportModel reporte;
  const SearchRadarScreen({super.key, required this.reporte});

  @override
  State<SearchRadarScreen> createState() => _SearchRadarScreenState();
}

class _SearchRadarScreenState extends State<SearchRadarScreen> {
  // Controlador nativo de Google Maps
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  double _distanciaEnMetros = 0.0;
  bool _estaDentroDelRadar = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  BitmapDescriptor? _targetIcon;
  BitmapDescriptor? _userIcon;

  // Mapa con estilo limpio sin POIs
  final String _mapStyle = '''
  [
    {
      "featureType": "poi",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "stylers": [{"visibility": "off"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _iniciarSeguimientoGPS();
    _generarIconosCanvas();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _generarIconosCanvas() async {
    _targetIcon = await _createIconFromMaterial(
      widget.reporte.colorUrgencia,
      Icons.warning_rounded,
    );
    _userIcon = await _createIconFromMaterial(Colors.red, Icons.person_pin);
    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _createIconFromMaterial(
    Color color,
    IconData iconData,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100;

    // Fondo semitransparente
    final Paint paint = Paint()..color = color.withValues(alpha: 0.2);
    // Borde sólido
    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4, paint);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 4,
      borderPaint,
    );

    // Dibujamos el Material Icon exacto en el centro
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 60.0,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _iniciarSeguimientoGPS() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null && mounted) {
      setState(() {
        _currentPosition = LatLng(
          lastPosition.latitude,
          lastPosition.longitude,
        );
      });
      _calcularMetricas(lastPosition);
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
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
    final double radioReporte = (widget.reporte.radio ?? 500).toDouble();
    setState(() {
      _distanciaEnMetros = distancia;
      _estaDentroDelRadar = distancia <= radioReporte;
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetReport = LatLng(
      widget.reporte.latitud,
      widget.reporte.longitud,
    );

    final Set<Marker> markers = {};
    if (_targetIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('target'),
          position: targetReport,
          icon: _targetIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    if (_currentPosition != null && _userIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _currentPosition!,
          icon: _userIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    final Set<Polyline> polylines = {};
    if (_currentPosition != null && !_estaDentroDelRadar) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('distance_line'),
          points: [_currentPosition!, targetReport],
          color: Colors.blue.shade800,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    final Set<Circle> circles = {
      Circle(
        circleId: const CircleId('radar_zone'),
        center: targetReport,
        radius: (widget.reporte.radio ?? 500).toDouble(),
        fillColor: Colors.blue.withValues(alpha: 0.15),
        strokeColor: Colors.blue.shade700,
        strokeWidth: 2,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Búsqueda (Radar)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: targetReport,
              zoom: 16.0,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(5.0, 19.0),
            markers: markers,
            circles: circles,
            polylines: polylines,
            rotateGesturesEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(_mapStyle);
            },
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
                  // Cambio de ! a ?
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 18),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: _currentPosition == null
                  ? Colors.white
                  : (_estaDentroDelRadar ? Colors.green.shade50 : Colors.white),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: _currentPosition == null
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 14),
                          Text(
                            'Calculando distancia...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : (_estaDentroDelRadar
                          ? Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green.shade700,
                                  size: 32,
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
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
                                    Icon(
                                      Icons.navigation_rounded,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Distancia al objetivo:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
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
                            )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
