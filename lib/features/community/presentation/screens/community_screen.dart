import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/listing_components.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // DATOS MOCK PARA LOS CARRUSELES
    final veterinarias = [
      {
        'image': 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=400&q=80',
        'title': 'Vet Pet Care',
        'subtitle': '⭐ 4.8 (120 reseñas)',
        'badge': '24/7'
      },
      {
        'image': 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=400&q=80',
        'title': 'Clínica San Roque',
        'subtitle': '⭐ 4.5 (89 reseñas)',
      },
      {
        'image': 'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?auto=format&fit=crop&w=400&q=80',
        'title': 'Animal Health',
        'subtitle': '⭐ 4.9 (200 reseñas)',
        'badge': 'Destacado'
      },
    ];

    final refugios = [
      {
        'image': 'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=400&q=80',
        'title': 'Huellitas de Amor',
        'subtitle': '⭐ 4.9 (340 reseñas)',
        'badge': 'Verificado'
      },
      {
        'image': 'https://images.unsplash.com/photo-1593134257782-e89567b7718a?auto=format&fit=crop&w=400&q=80',
        'title': 'Refugio Esperanza',
        'subtitle': '⭐ 4.7 (150 reseñas)',
      },
      {
        'image': 'https://images.unsplash.com/photo-1553322378-eb94e5966b0c?auto=format&fit=crop&w=400&q=80',
        'title': 'Adopta un Amigo',
        'subtitle': '⭐ 4.6 (90 reseñas)',
      },
    ];

    final adopta = [
      {
        'image': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=400&q=80',
        'title': 'Max',
        'subtitle': 'Beagle • 2 años',
        'badge': 'Urgente'
      },
      {
        'image': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=400&q=80',
        'title': 'Luna',
        'subtitle': 'Mestiza • 6 meses',
      },
      {
        'image': 'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=400&q=80',
        'title': 'Simba',
        'subtitle': 'Gato Persa • 1 año',
      },
    ];

    // AQUÍ VA EL CAMBIO: PopScope intercepta el botón/gesto de "Back" de Android/iOS
    return PopScope(
      canPop: true, // Permite la salida natural activando la animación inversa de GoRouter
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            // AQUÍ VA EL CAMBIO: Aumentamos la altura del 88% al 96%
            height: screenHeight * 0.96,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 25,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                // BARRA SUPERIOR (Indicador, Título y Botón de Cierre)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 16.0, right: 16.0),
                  child: Column(
                    children: [
                      // Handle táctil (Permite también hacer tap para cerrar)
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              'RESCUENET',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                              ),
                              // Al presionar la X se ejecuta context.pop() que hace caer la lámina
                              onPressed: () => context.pop(), 
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // CONTENIDO DESLIZABLE
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 40, top: 10),
                    child: Column(
                      children: [
                        ListingSection(title: 'Veterinarias', items: veterinarias),
                        ListingSection(title: 'Refugios', items: refugios),
                        ListingSection(title: 'Adopta', items: adopta),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}