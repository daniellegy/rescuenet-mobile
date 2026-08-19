import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CitySearchModal extends StatelessWidget {
  final void Function(String label, LatLng position) onCitySelected;

  const CitySearchModal({super.key, required this.onCitySelected});

  @override
  Widget build(BuildContext context) {
    // Diccionario de ciudades extraído del componente principal
    final Map<String, Map<String, LatLng>> regionesPorCiudad = {
      'Puebla': {
        'Puebla Centro': const LatLng(19.0414, -98.2063),
        'Cholula': const LatLng(19.0605, -98.3047),
        'Atlixco': const LatLng(18.9042, -98.4384),
      },
      'Minatitlán': {
        'Minatitlán Centro': const LatLng(17.9895, -94.5559),
        'Cosoleacaque': const LatLng(17.9972, -94.6339),
        'El Naranjito': const LatLng(18.0050, -94.5761),
      },
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Buscar Ciudad o Región...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: regionesPorCiudad.entries.map((ciudad) {
                    return ExpansionTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        ciudad.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: ciudad.value.entries.map((region) {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 40,
                            right: 16,
                          ),
                          leading: const Icon(Icons.map, color: Colors.grey),
                          title: Text(region.key),
                          onTap: () {
                            Navigator.pop(context);
                            onCitySelected(
                              '${ciudad.key}, ${region.key}',
                              region.value,
                            );
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
