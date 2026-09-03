import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void _mostrarImagenExpandida(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            maxScale: 4.0,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}

// Carrusel interactivo para mostrar la evidencia fotográfica
class ReportImageCarousel extends StatefulWidget {
  final List<String> photos;
  const ReportImageCarousel({super.key, required this.photos});
  @override
  State<ReportImageCarousel> createState() => _ReportImageCarouselState();
}

class _ReportImageCarouselState extends State<ReportImageCarousel> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() => _currentPhotoIndex = index);
            },
            itemBuilder: (context, index) => GestureDetector(
              onTap: () =>
                  _mostrarImagenExpandida(context, widget.photos[index]),
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        if (widget.photos.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photos.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPhotoIndex == index
                        ? Colors.white
                        : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Fila para detalles estáticos (Raza, Color, Tamaño, etc.)
class ReportDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const ReportDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

/// Fila interactiva para mostrar usuarios (Reportante o Rescatista)
class ReportPersonRow extends StatelessWidget {
  final String role;
  final String name;
  final String? fotoUrl;
  final int? userId;
  final bool isRescatista;

  const ReportPersonRow({
    super.key,
    required this.role,
    required this.name,
    this.fotoUrl,
    this.userId,
    this.isRescatista = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          if (userId != null) {
            context.push('/user-info', extra: userId);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isRescatista
                    ? (isDark ? Colors.green.shade900 : Colors.green.shade100)
                    : (isDark
                          ? Colors.blueGrey.shade800
                          : Colors.blueGrey.shade100),
                backgroundImage: fotoUrl != null
                    ? NetworkImage(fotoUrl!)
                    : null,
                child: fotoUrl == null
                    ? Icon(
                        isRescatista
                            ? Icons.volunteer_activism_rounded
                            : Icons.person,
                        size: 16,
                        color: isRescatista
                            ? (isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade800)
                            : (isDark
                                  ? Colors.blueGrey.shade300
                                  : Colors.blueGrey.shade800),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                '$role: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black87,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila para la cronología y el seguimiento del rescate
class ReportPhaseRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const ReportPhaseRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.blueGrey.shade500 : Colors.blueGrey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
