import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String? _seccionExpandida; // 'veterinarias', 'refugios' o null

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _cerrarPantalla() {
    _slideController.reverse().then((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _abrirEnGoogleMaps(String titulo, String ubicacion) async {
    final query = Uri.encodeComponent('$titulo, $ubicacion');
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // AQUÍ VA EL CAMBIO: Eliminamos cálculos rígidos de altura del modal
    // Solo necesitamos saber el offset superior seguro.
    final double topOffset = MediaQuery.of(context).padding.top + 20;

    final veterinarias = [
      {
        'title': 'Hospital Veterinario Puebla',
        'rating': '4.8',
        'reviews': '342',
        'location': 'Zavaleta, Puebla',
        'badge': '24/7',
        'icon': Icons.local_hospital_rounded,
      },
      {
        'title': 'Clínica Vet. San Francisco',
        'rating': '4.6',
        'reviews': '128',
        'location': 'Centro Histórico, Puebla',
        'badge': null,
        'icon': Icons.medical_services_rounded,
      },
      {
        'title': 'VetCare Animal Hospital',
        'rating': '4.9',
        'reviews': '450',
        'location': 'Angelópolis, Puebla',
        'badge': 'Destacado',
        'icon': Icons.local_hospital_rounded,
      },
      {
        'title': 'Veterinaria La Paz',
        'rating': '4.7',
        'reviews': '210',
        'location': 'Col. La Paz, Puebla',
        'badge': null,
        'icon': Icons.medical_services_rounded,
      },
      {
        'title': 'Hospital Vet. Animalia',
        'rating': '4.5',
        'reviews': '89',
        'location': 'Cholula, Puebla',
        'badge': 'Económico',
        'icon': Icons.local_hospital_rounded,
      },
    ];

    final refugios = [
      {
        'title': 'Ángeles Peludos Puebla',
        'rating': '4.9',
        'reviews': '512',
        'location': 'A.C. Centro, Puebla',
        'badge': 'Verificado',
        'icon': Icons.pets_rounded,
      },
      {
        'title': 'Fundación Rufo',
        'rating': '4.8',
        'reviews': '320',
        'location': 'Rescate Animal, Cuautlancingo',
        'badge': 'Dona',
        'icon': Icons.volunteer_activism_rounded,
      },
      {
        'title': 'Clínica Perro Callejero',
        'rating': '4.7',
        'reviews': '215',
        'location': 'Esterilización y Rescate',
        'badge': null,
        'icon': Icons.healing_rounded,
      },
      {
        'title': 'Adopta Un Amigo Puebla',
        'rating': '4.9',
        'reviews': '400',
        'location': 'Centro de Adopciones',
        'badge': 'Destacado',
        'icon': Icons.other_houses_rounded,
      },
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _cerrarPantalla();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,

        body: Stack(
          children: [
            // Fondo oscuro protector, sin cortes
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) => GestureDetector(
                  onTap: _cerrarPantalla,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.5 * _slideController.value,
                    ),
                  ),
                ),
              ),
            ),

            // Modal Cristal, ahora abarca hasta abajo libremente
            Positioned(
              top: topOffset,
              left: 0,
              right: 0,
              bottom: 0, // Se estira hasta abajo para no cortar
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      double dy = details.primaryDelta! / screenHeight;
                      _slideController.value -= dy;
                    },
                    onVerticalDragEnd: (details) {
                      if (_slideController.value < 0.75 ||
                          details.primaryVelocity! > 300) {
                        _cerrarPantalla();
                      } else {
                        _slideController.forward();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFF8F9FA),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 25,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 12.0,
                              bottom: 0.0,
                              left: 16.0,
                              right: 16.0,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 44,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 20,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.grey
                                              .withValues(alpha: 0.1),
                                        ),
                                        onPressed: _cerrarPantalla,
                                      ),
                                    ),
                                    const Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'DIRECTORIO',
                                        style: TextStyle(
                                          fontFamily: 'Archivo Black',
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              // AQUÍ VA EL CAMBIO: El padding bottom lo lleva el SCROLL para protegerse de la Navbar,
                              // pero el contenedor en sí no está cortado.
                              padding: EdgeInsets.only(
                                bottom:
                                    90 + MediaQuery.of(context).padding.bottom,
                                top: 10,
                              ),
                              child: Column(
                                children: [
                                  if (_seccionExpandida == null ||
                                      _seccionExpandida == 'veterinarias')
                                    _buildCommunitySection(
                                      'Veterinarias Cercanas',
                                      veterinarias,
                                      isDark,
                                      _seccionExpandida == 'veterinarias',
                                      () {
                                        setState(() {
                                          _seccionExpandida =
                                              _seccionExpandida ==
                                                  'veterinarias'
                                              ? null
                                              : 'veterinarias';
                                        });
                                      },
                                    ),

                                  if (_seccionExpandida == null ||
                                      _seccionExpandida == 'refugios')
                                    _buildCommunitySection(
                                      'Refugios y Fundaciones',
                                      refugios,
                                      isDark,
                                      _seccionExpandida == 'refugios',
                                      () {
                                        setState(() {
                                          _seccionExpandida =
                                              _seccionExpandida == 'refugios'
                                              ? null
                                              : 'refugios';
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunitySection(
    String title,
    List<Map<String, dynamic>> items,
    bool isDark,
    bool showAll,
    VoidCallback onToggle,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayItems = showAll ? items : items.take(3).toList();
    final bool canExpand = items.length > 3 || showAll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Archivo Black',
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (canExpand)
                TextButton(
                  onPressed: onToggle,
                  child: Text(
                    showAll ? 'Ocultar listado' : 'Ver directorio',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showAll)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) =>
                _buildTacticalListCard(displayItems[index], isDark),
          )
        else
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20.0,
                    right: index == displayItems.length - 1 ? 20.0 : 0,
                  ),
                  child: _buildTacticalCarouselCard(
                    displayItems[index],
                    isDark,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTacticalCarouselCard(Map<String, dynamic> item, bool isDark) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    item['icon'] as IconData,
                    size: 36,
                    color: Colors.blueAccent,
                  ),
                ),
                if (item['badge'] != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['badge'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${item['rating']} (${item['reviews']})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['location'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalListCard(Map<String, dynamic> item, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['icon'] as IconData,
                size: 32,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${item['rating']} (${item['reviews']} opiniones)',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['location'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.map_rounded,
                color: Colors.blueAccent,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
              ),
              onPressed: () {
                _abrirEnGoogleMaps(
                  item['title'] as String,
                  item['location'] as String,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
