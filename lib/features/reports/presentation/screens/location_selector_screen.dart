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
  late MapController _mapController;
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
          // El mapa al fondo
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentLat, _currentLng),
              initialZoom: 18.0,
              minZoom: 5.0,
              maxZoom: 22.0,
              // Capturamos el movimiento del mapa en tiempo real
              onPositionChanged: (MapCamera position, bool hasGesture) {
                if (position.center != null) {
                  _currentLat = position.center!.latitude;
                  _currentLng = position.center!.longitude;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
                additionalOptions: {
                  'accessToken': mapboxToken,
                  'id': 'mapbox/streets-v12',
                },
              ),
            ],
          ),
          
          // El PIN fijo en el centro exacto de la pantalla
          const Padding(
            padding: EdgeInsets.only(bottom: 40.0), // Ajuste para que la "punta" del icono sea el centro exacto
            child: Icon(
              Icons.location_on,
              size: 50.0,
              color: Colors.red,
            ),
          ),
          
          // Letrero indicador flotante
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Mueve el mapa para ajustar el PIN',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      
      // Botón para confirmar la selección y regresar los datos
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, {
            'lat': _currentLat,
            'lng': _currentLng,
          });
        },
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check),
        label: const Text('Confirmar Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}