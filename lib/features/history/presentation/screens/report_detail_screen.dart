import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reporte;

  const ReportDetailScreen({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    // Extraemos los datos con valores por defecto por si alguno es nulo
    final fotoUrl = reporte['foto_url'];
    final especie = reporte['especie'] ?? 'Animal';
    final color = reporte['color_dominante'] ?? 'No especificado';
    final referencias = reporte['referencias'] ?? 'Sin descripción adicional.';
    final lat = reporte['latitud']?.toStringAsFixed(4) ?? '0.0000';
    final lng = reporte['longitud']?.toStringAsFixed(4) ?? '0.0000';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalles del Caso'),
        backgroundColor: Colors.white,
        elevation: 0, // Sin sombra para que se funda con el diseño
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Imagen a todo lo ancho (Sin la etiqueta "Activo")
            if (fotoUrl != null)
              Image.network(
                fotoUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
                child: const Icon(Icons.pets, size: 80, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Ubicación
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ubicación del reporte', // Idealmente usarías Geocoding para obtener "Parque Centenario"
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$lat, $lng',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Tiempo / Reportador
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reportado recientemente', // Necesitas un campo created_at en tu BD para calcular el tiempo real
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Especie: $especie • Color: $color',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  const SizedBox(height: 24),

                  // 4. Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    referencias,
                    style: const TextStyle(
                      fontSize: 15, 
                      color: Color(0xFF4A4A4A),
                      height: 1.5, // Interlineado para mejor lectura
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // 5. Botón de Acción en la parte inferior anclado
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FilledButton(
            onPressed: () {
              // Lógica para aceptar el caso
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F), // Rojo RescueNet
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Aceptar Caso',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}