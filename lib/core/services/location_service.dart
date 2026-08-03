import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationService {
  /// Obtiene la ubicación del usuario optimizando el tiempo de respuesta.
  /// [requestPermission] define si se debe mostrar el diálogo de permisos al usuario (ideal apagarlo para providers de fondo).
  Future<Position> getCurrentPosition({bool requestPermission = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están desactivados.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestPermission) {
        throw Exception('Permisos denegados (modo silencioso).');
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación fueron denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permisos denegados permanentemente.');
    }

    // 1. OPTIMIZACIÓN DE VELOCIDAD: Buscamos la última ubicación en caché
    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      // Si la ubicación tiene menos de 5 minutos de antigüedad, la retornamos instantáneamente
      if (DateTime.now().difference(position.timestamp).inMinutes < 5) {
        return position;
      }
    }

    // 2. Si no hay caché válida, encendemos el hardware GPS pero con un Timeout estricto de 4 segundos
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy
              .medium, // 'medium' es mucho más rápido y perfecto para distancias de kilómetros
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // Si hace timeout pero teníamos una posición vieja, preferimos devolver la vieja a fallar por completo
      if (position != null) {
        return position;
      }
      throw Exception('No se pudo obtener la ubicación actual a tiempo.');
    }
  }

  Stream<Position> getLiveLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter:
            10, // Actualiza solo cuando el usuario se mueva 10 metros
      ),
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});
