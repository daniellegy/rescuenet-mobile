import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationSelectorScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  const LocationSelectorScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });
  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  late final MapController _mapController;
  late double _currentLat;
  late double _currentLng;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
  }

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar Ubicación'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentLat, _currentLng),
              initialZoom: 18.0,
              minZoom: 5.0,
              maxZoom: 22.0,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  const LatLng(14.53, -118.36),
                  const LatLng(32.71, -86.71),
                ),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                enableMultiFingerGestureRace: false,
              ),
              onPositionChanged: (MapCamera position, bool hasGesture) {
                _currentLat = position.center.latitude;
                _currentLng = position.center.longitude;
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 40.0),
            child: Icon(Icons.location_on, size: 50.0, color: Colors.red),
          ),
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Mueve el mapa para ajustar el PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, {'lat': _currentLat, 'lng': _currentLng});
        },
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check),
        label: const Text(
          'Confirmar Ubicación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
