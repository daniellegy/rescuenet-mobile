import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/local_reports_tab.dart';
import '../widgets/my_reports_tab.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const ReportsScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cerrarPantalla();
        }
      },
      child: Material(
        color: Colors.transparent, // Permite ver el mapa detrás
        child: Stack(
          children: [
            // Fondo oscuro semitransparente
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
            // Panel deslizable
            Align(
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
                    height: screenHeight * 0.95,
                    padding: const EdgeInsets.only(
                      bottom: 70,
                    ), // Margen para protegerse de la navbar
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
                        // HEADER Y LÍNEA DE ARRASTRE
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 12.0,
                            bottom: 8.0,
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
                                        backgroundColor: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      onPressed: _cerrarPantalla,
                                    ),
                                  ),
                                  const Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'REPORTES',
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
                        // CONTENIDO Y PESTAÑAS
                        Expanded(
                          child: DefaultTabController(
                            key: ValueKey(widget.initialIndex),
                            length: 2,
                            initialIndex: widget.initialIndex,
                            child: Column(
                              children: [
                                const TabBar(
                                  indicatorColor: Colors.blueAccent,
                                  labelColor: Colors.blueAccent,
                                  unselectedLabelColor: Colors.grey,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  tabs: [
                                    Tab(text: 'REPORTES LOCALES'),
                                    Tab(text: 'HISTORIAL'),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      LocalReportsTab(isDark: isDark),
                                      MyReportsTab(isDark: isDark),
                                    ],
                                  ),
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
          ],
        ),
      ),
    );
  }
}
