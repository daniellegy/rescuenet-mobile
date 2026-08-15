import 'package:flutter/material.dart';

// 1. EL HEADER DE LA SECCIÓN (Título + Botón "Ver más")
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeMore;

  const SectionHeader({super.key, required this.title, required this.onSeeMore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          TextButton(
            onPressed: onSeeMore,
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueAccent,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Ver más'),
          ),
        ],
      ),
    );
  }
}

// 2. LA TARJETA INDIVIDUAL (ListingCard)
class ListingCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String? badge;

  const ListingCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 160, // Ancho fijo para las tarjetas del carrusel
      margin: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MEDIA (Imagen + Favorito + Badge)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120, color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
              // Botón de Favorito
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.white, size: 18),
                ),
              ),
              // Badge Opcional (Ej. "Urgente", "Destacado")
              if (badge != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // DETALLES (Título + Subtítulo/Rating/Precio)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 3. EL CARRUSEL (ListingCarousel)
class ListingCarousel extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const ListingCarousel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // Altura total reservada para el carrusel
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          // Añadimos un margen derecho al último elemento para que no quede pegado al borde de la pantalla
          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 20.0 : 0),
            child: ListingCard(
              imageUrl: item['image'],
              title: item['title'],
              subtitle: item['subtitle'],
              badge: item['badge'],
            ),
          );
        },
      ),
    );
  }
}

// 4. LA SECCIÓN COMPLETA (Header + Carrusel)
class ListingSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const ListingSection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onSeeMore: () {
            // TODO: Navegar a lista completa en el futuro
          },
        ),
        ListingCarousel(items: items),
        const SizedBox(height: 24), // Espaciador inferior entre secciones
      ],
    );
  }
}