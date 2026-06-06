import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Importante para la cámara
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

const MAPBOX_ACCESS_TOKEN =
    'pk.eyJ1IjoiZWR1NTEyIiwiYSI6ImNtcHZlNHgxZzIzdmQyc29oeXV2ZnVhNjQifQ.rPhYjFYEQYUKkdovcabpxQ';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  LatLng? myPosition;

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

  // LÓGICA DE CAPTURA ÁGIL
  Future<void> _takePhotoAndNavigate() async {
    if (myPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null && mounted) {
      // Navegamos al formulario pasando coordenadas Y la foto
      context.push(
        '/create-report',
        extra: {
          'lat': myPosition!.latitude,
          'lng': myPosition!.longitude,
          'imagePath': pickedFile.path,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Permite que el mapa pase por debajo de la barra transparente
      appBar: AppBar(
        title: const Text('Mapa de rescates'),
        backgroundColor: Colors.white.withOpacity(
          0.9,
        ), // Ligeramente transparente
        actions: [
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
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$MAPBOX_ACCESS_TOKEN',
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
                    ),
                  ],
                ),
              ],
            ),

      // 1. Posicionamos el botón en el centro de la barra inferior
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 2. El botón de la cámara (Rojo sólido)
      floatingActionButton: FloatingActionButton(
        onPressed: _takePhotoAndNavigate,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(), // Asegura que sea completamente redondo
        child: const Icon(Icons.add_a_photo, size: 28),
      ),

      // 3. La barra de navegación inferior con el diseño solicitado
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0, // Espacio entre el botón y la barra
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Lado Izquierdo (Iconos inactivos por ahora, color rojo)
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.red),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.article, color: Colors.red),
                onPressed: () => context.push('/history'),
              ),

              const SizedBox(width: 48), // Espacio central para la muesca
              // Lado Derecho (Iconos inactivos por ahora, color gris simulando inactividad)
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.grey),
                onPressed: () {},

              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
