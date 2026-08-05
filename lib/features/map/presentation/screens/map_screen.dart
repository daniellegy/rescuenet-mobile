import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/camera_service.dart';
import '../providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/urgency_filter_menu.dart';
import '../widgets/active_rescue_card.dart';
import '../widgets/map_bottom_nav_bar.dart';
import '../widgets/off_screen_markers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  LatLng? myPosition;
  late final MapController _mapController;
  StreamSubscription<Position>? _positionStream;
  String _filtroUrgencia = 'todos';
  bool _showUrgencyMenu = false;
  bool _seguirUsuario = true;

  late AnimationController _holdController;
  Offset? _holdPosition;
  Timer? _intentTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _holdController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        )..addListener(() {
          setState(() {});
        });
    _iniciarLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    _holdController.dispose();
    _intentTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _holdPosition = event.localPosition;
    _intentTimer?.cancel();
    _intentTimer = Timer(const Duration(milliseconds: 100), () {
      if (_holdPosition != null && mounted) {
        _holdController.forward(from: 0.0);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_holdPosition != null) {
      final distance = (event.localPosition - _holdPosition!).distance;
      if (distance > 15) {
        _cancelPointer();
      }
    }
  }

  void _onPointerUp(PointerEvent event) {
    _cancelPointer();
  }

  void _cancelPointer() {
    _intentTimer?.cancel();
    if (_holdController.isAnimating || _holdController.value > 0) {
      _holdController.reset();
    }
    if (_holdPosition != null && mounted) {
      setState(() {
        _holdPosition = null;
      });
    }
  }

  Future<void> _iniciarLiveTracking() async {
    final locationService = ref.read(locationServiceProvider);
    try {
      final initialPos = await locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          myPosition = LatLng(initialPos.latitude, initialPos.longitude);
        });
      }
      _positionStream = locationService.getLiveLocationStream().listen((
        Position position,
      ) {
        if (mounted) {
          setState(() {
            myPosition = LatLng(position.latitude, position.longitude);
            if (_seguirUsuario) {
              _mapController.move(myPosition!, _mapController.camera.zoom);
            }
          });
        }
      });
      ref.invalidate(reportesActivosMapaProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _takePhotoAndNavigate({LatLng? customPoint}) async {
    final targetPosition = customPoint ?? myPosition;
    if (targetPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }
    try {
      final cameraService = ref.read(cameraServiceProvider);
      final pickedFile = await cameraService.takePicture();
      if (pickedFile != null && mounted) {
        context.push(
          '/create-report',
          extra: {
            'lat': targetPosition.latitude,
            'lng': targetPosition.longitude,
            'imagePath': pickedFile.path,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildReportMarker(Color urgencyColor, {bool isInProgress = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: urgencyColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: urgencyColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        isInProgress ? Icons.hourglass_top_rounded : Icons.warning_rounded,
        color: urgencyColor,
        size: 24,
      ),
    );
  }

  void _mostrarPerfilDirecto() {
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      context.push('/user-info', extra: userId);
    }
  }

  void _refrescarMapaManual() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Actualizando emergencias en tu zona...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    ref.invalidate(reportesActivosMapaProvider);
    ref.invalidate(miRescateActivoProvider);
  }

  @override
  Widget build(BuildContext context) {
    final mapboxToken = dotenv.env['MAPBOX_TOKEN'] ?? '';
    final reportesAsync = ref.watch(reportesActivosMapaProvider);
    final miRescateAsync = ref.watch(miRescateActivoProvider);

    final bool hasActiveRescue = miRescateAsync.maybeWhen(
      data: (rescate) => rescate != null,
      orElse: () => false,
    );

    // Integración de Mapa Adaptativo:
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapStyle = isDark ? 'mapbox/dark-v11' : 'mapbox/streets-v12';
    final appBarBg = isDark ? const Color(0xE6121212) : const Color(0xE6FFFFFF);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Mapa de rescate'),
        backgroundColor: appBarBg,
        actions: [
          reportesAsync.maybeWhen(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            orElse: () => IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: _refrescarMapaManual,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            tooltip: 'Configuración',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: myPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerUp,
                  child: RepaintBoundary(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: myPosition!,
                        initialZoom: 18,
                        minZoom: 5,
                        maxZoom: 19,
                        cameraConstraint: CameraConstraint.contain(
                          bounds: LatLngBounds(
                            const LatLng(-90.0, -180.0),
                            const LatLng(90.0, 180.0),
                          ),
                        ),
                        onPositionChanged:
                            (MapCamera position, bool hasGesture) {
                              if (hasGesture && _seguirUsuario) {
                                setState(() {
                                  _seguirUsuario = false;
                                });
                              }
                            },
                        onTap: (tapPosition, point) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Mantén presionado en cualquier parte para reportar una emergencia ahí',
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onLongPress: (tapPosition, point) {
                          _cancelPointer();
                          _takePhotoAndNavigate(customPoint: point);
                        },
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          enableMultiFingerGestureRace: false,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.mapbox.com/styles/v1/$mapStyle/tiles/{z}/{x}/{y}?access_token=$mapboxToken',
                          additionalOptions: {
                            'accessToken': mapboxToken,
                            'id': mapStyle,
                          },
                          evictErrorTileStrategy:
                              EvictErrorTileStrategy.dispose,
                        ),
                        MarkerLayer(
                          rotate: true,
                          markers: [
                            if (myPosition != null)
                              Marker(
                                point: myPosition!,
                                width: 50,
                                height: 50,
                                rotate: true,
                                child: GestureDetector(
                                  onTap: _mostrarPerfilDirecto,
                                  child: const RepaintBoundary(
                                    child: Icon(
                                      Icons.person_pin,
                                      color: Colors.blue,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ...reportesAsync.maybeWhen(
                              data: (reportes) {
                                return reportes
                                    .where(
                                      (r) =>
                                          _filtroUrgencia == 'todos' ||
                                          r.urgencia.toLowerCase() ==
                                              _filtroUrgencia,
                                    )
                                    .map((reporte) {
                                      final bool estaEnProceso =
                                          reporte.estado
                                              .toString()
                                              .trim()
                                              .toUpperCase() ==
                                          'EN_PROCESO';
                                      return Marker(
                                        point: LatLng(
                                          reporte.latitud,
                                          reporte.longitud,
                                        ),
                                        width: 50,
                                        height: 50,
                                        rotate: true,
                                        child: GestureDetector(
                                          onTap: () {
                                            context
                                                .push(
                                                  '/report-detail',
                                                  extra: reporte,
                                                )
                                                .then((_) {
                                                  ref.invalidate(
                                                    reportesActivosMapaProvider,
                                                  );
                                                  ref.invalidate(
                                                    miRescateActivoProvider,
                                                  );
                                                });
                                          },
                                          child: _buildReportMarker(
                                            reporte.colorUrgencia,
                                            isInProgress: estaEnProceso,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList();
                              },
                              orElse: () => [],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (_holdPosition != null && _holdController.isAnimating)
                  Positioned(
                    left: _holdPosition!.dx - 30,
                    top: _holdPosition!.dy - 30,
                    child: IgnorePointer(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          value: _holdController.value,
                          color: Colors.redAccent,
                          strokeWidth: 5,
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                reportesAsync.maybeWhen(
                  data: (reportes) {
                    final reportesFiltrados = reportes.where((r) {
                      if (_filtroUrgencia == 'todos') {
                        return true;
                      }
                      return r.urgencia.toLowerCase() == _filtroUrgencia;
                    }).toList();
                    return OffScreenMarkers(
                      mapController: _mapController,
                      reportes: reportesFiltrados,
                      topMargin: hasActiveRescue ? 110.0 : 24.0,
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                Positioned(
                  bottom: 200,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton(
                        heroTag: 'toggle_filter_btn',
                        mini: true,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.white,
                        foregroundColor: isDark
                            ? Colors.white
                            : Colors.blueGrey,
                        elevation: 4,
                        onPressed: () {
                          setState(() {
                            _showUrgencyMenu = !_showUrgencyMenu;
                          });
                        },
                        child: Icon(
                          _showUrgencyMenu
                              ? Icons.close_rounded
                              : Icons.filter_list_rounded,
                        ),
                      ),
                      if (_showUrgencyMenu) ...[
                        const SizedBox(height: 12),
                        UrgencyFilterMenu(
                          currentFilter: _filtroUrgencia,
                          onFilterChanged: (newFilter) {
                            setState(() {
                              _filtroUrgencia = newFilter;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  bottom: 140,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'my_location_btn',
                    mini: true,
                    backgroundColor: _seguirUsuario
                        ? (isDark ? Colors.blue.shade900 : Colors.blue.shade50)
                        : (isDark ? Colors.grey.shade800 : Colors.white),
                    foregroundColor: _seguirUsuario
                        ? (isDark
                              ? Colors.blueAccent.shade100
                              : Colors.blueAccent)
                        : Colors.grey,
                    elevation: 4,
                    child: const Icon(Icons.my_location),
                    onPressed: () {
                      setState(() {
                        _seguirUsuario = true;
                      });
                      if (myPosition != null) {
                        _mapController.move(myPosition!, 18);
                      }
                    },
                  ),
                ),
                miRescateAsync.maybeWhen(
                  data: (rescate) {
                    if (rescate == null) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: SafeArea(
                        child: ActiveRescueCard(rescate: rescate),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _takePhotoAndNavigate(),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_a_photo, size: 28),
      ),
      bottomNavigationBar: const MapBottomNavBar(),
    );
  }
}
