import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

const MAPBOX_ACCESS_TOKEN = 
'pk.eyJ1IjoiZWR1NTEyIiwiYSI6ImNtcHZlNHgxZzIzdmQyc29oeXV2ZnVhNjQifQ.rPhYjFYEQYUKkdovcabpxQ';

// 1. Cambiamos ConsumerWidget por ConsumerStatefulWidget
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

// 2. El estado ahora extiende de ConsumerState
class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? myPosition;

  // 3. Ahora sí podemos usar initState de forma segura
  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<Position> determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permisos de ubicación denegados');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permisos denegados permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }

  void getCurrentLocation() async {
    try {
      Position position = await determinePosition();
      setState(() {
        myPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error obteniendo ubicación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // En Riverpod, 'ref' ya está disponible globalmente dentro de un ConsumerState,
    // por lo que no necesitas pasarlo como parámetro en el método build.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Rescates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // ref está disponible automáticamente aquí
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      // 4. Reemplazamos el texto con la lógica de carga y el mapa
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
                  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$MAPBOX_ACCESS_TOKEN',
                  additionalOptions: const {
                    'accessToken': MAPBOX_ACCESS_TOKEN,
                    'id': 'mapbox/streets-v12',
                  },
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: myPosition!,
                      child: const Icon(
                        Icons.person_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    )
                  ],
                ),
              ],
            ),
    );
  }
}