import 'package:flutter/material.dart';
// AQUÍ VA EL CAMBIO: Quitamos flutter_map, latlong2 y dotenv. Ahora usamos Google Maps puro.
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  // Usamos el controlador nativo de Google Maps
  GoogleMapController? _mapController;
  late double _currentLat;
  late double _currentLng;

  // Mantenemos el mapa limpio
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
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar Ubicación'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentLat, _currentLng),
              zoom: 18.0,
            ),
            minMaxZoomPreference: const MinMaxZoomPreference(5.5, 22.0),
            // Restringimos la cámara a los límites de México aprox
            cameraTargetBounds: CameraTargetBounds(
              LatLngBounds(
                southwest: const LatLng(10.0, -120.0),
                northeast: const LatLng(35.0, -84.0),
              ),
            ),
            // Apagamos la rotación para no desorientar al usuario al elegir ubicación
            rotateGesturesEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapController?.setMapStyle(_mapStyle);
            },
            onCameraMove: (CameraPosition position) {
              _currentLat = position.target.latitude;
              _currentLng = position.target.longitude;
            },
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
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
          // Retornamos las coordenadas de donde quedó apuntando el mapa
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
