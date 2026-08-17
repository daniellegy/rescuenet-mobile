import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/services/camera_service.dart';
import '../providers/map_markers_provider.dart';
import '../../../reports/presentation/providers/my_active_rescue_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/active_rescue_card.dart';
import '../widgets/off_screen_markers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ValueNotifier<LatLng?> _myPosition = ValueNotifier(null);
  final ValueNotifier<double> _myHeading = ValueNotifier(0.0);
  final ValueNotifier<bool> _seguirUsuario = ValueNotifier(true);
  final ValueNotifier<Offset?> _holdPosition = ValueNotifier(null);
  final ValueNotifier<CameraPosition?> _cameraPosition = ValueNotifier(null);

  LatLng? _initialPosition;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  String _filtroUrgencia = 'todos';
  String _filtroEspecie = 'todos';
  
  // Distancia predeterminada a "Todas" (999 km)
  double _filtroDistancia = 999.0;
  
  String _ciudadSeleccionadaLabel = 'Buscar Ciudad o Región...';

  late AnimationController _holdController;
  Timer? _intentTimer;

  final Map<String, BitmapDescriptor> _customIcons = {};
  BitmapDescriptor? _userMarkerIcon;
  
  Brightness? _lastBrightness;

  final String _mapStyleLight = '''
    [{"featureType": "poi", "stylers": [{"visibility": "off"}]},
    {"featureType": "transit", "stylers": [{"visibility": "off"}]}]
  ''';

  final String _mapStyleDark = '''
    [{"elementType": "geometry", "stylers": [{"color": "#212121"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
    {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
    {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
    {"featureType": "poi", "stylers": [{"visibility": "off"}]},
    {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
    {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#8a8a8a"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#3c3c3c"}]},
    {"featureType": "transit", "stylers": [{"visibility": "off"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]},
    {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}]}]
  ''';

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _generarTodosLosIconos().then((_) {
      _iniciarLiveTracking();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    _holdController.dispose();
    _intentTimer?.cancel();

    _myPosition.dispose();
    _myHeading.dispose();
    _seguirUsuario.dispose();
    _holdPosition.dispose();
    _cameraPosition.dispose();
    super.dispose();
  }

  void _actualizarEtiquetaCiudadSegunUbicacion(LatLng pos) {
    final distPuebla = Geolocator.distanceBetween(
      pos.latitude, pos.longitude, 19.0414, -98.2063,
    );
    final distMina = Geolocator.distanceBetween(
      pos.latitude, pos.longitude, 17.9895, -94.5559,
    );

    if (distPuebla < 50000) {
      setState(() => _ciudadSeleccionadaLabel = 'Puebla (Mi ubicación)');
    } else if (distMina < 50000) {
      setState(() => _ciudadSeleccionadaLabel = 'Minatitlán (Mi ubicación)');
    } else {
      setState(() => _ciudadSeleccionadaLabel = 'Ubicación actual');
    }
  }

  Future<void> _generarTodosLosIconos() async {
    // AQUÍ VA EL CAMBIO 1: Nueva paleta de colores de intensidad máxima
    final colores = {
      'alta': const Color(0xFFD50000), // Rojo Intenso (Material Red 700)
      'media': const Color(0xFFFF6D00), // Naranja Más Intenso
      'baja': const Color(0xFFFFD600), // Amarillo Brillante
    };
    final emojis = {
      'perro': '🐶',
      'gato': '🐱',
      'silvestre': '🦝', 
      'default': '🐾',
    };

    for (var col in colores.entries) {
      for (var em in emojis.entries) {
        final icon = await _crearMarcadorCanvas(col.value, em.value);
        _customIcons['${col.key}_${em.key}'] = icon;
      }
    }
    _userMarkerIcon = await _crearUserMarkerCanvas();
    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _crearUserMarkerCanvas() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120;
    const double centerPoint = size / 2;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(
      const Offset(centerPoint, centerPoint + 4),
      30,
      shadowPaint,
    );

    final Paint paint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(const Offset(centerPoint, centerPoint), 30, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(const Offset(centerPoint, centerPoint), 30, borderPaint);

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _crearMarcadorCanvas(
    Color color,
    String emoji,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    const double size = 110;
    const double radius = 45;
    const double centerPoint = size / 2;

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(
      const Offset(centerPoint, centerPoint + 4),
      radius,
      shadowPaint,
    );
    
    canvas.drawCircle(const Offset(centerPoint, centerPoint), radius, paint);

    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      const Offset(centerPoint, centerPoint),
      radius - 8,
      whitePaint,
    );

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: emoji,
      style: const TextStyle(fontSize: 44),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerPoint - (textPainter.width / 2),
        centerPoint - (textPainter.height / 2),
      ),
    );

    final ui.Image img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_seguirUsuario.value) {
      _seguirUsuario.value = false;
    }
    _holdPosition.value = event.localPosition;
    _intentTimer?.cancel();
    _intentTimer = Timer(const Duration(milliseconds: 100), () {
      if (_holdPosition.value != null && mounted) {
        _holdController.forward(from: 0.0);
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_holdPosition.value != null) {
      final distance = (event.localPosition - _holdPosition.value!).distance;
      if (distance > 15) {
        _cancelPointer();
      }
    }
  }

  void _onPointerUp(PointerEvent event) => _cancelPointer();

  void _cancelPointer() {
    _intentTimer?.cancel();
    if (_holdController.isAnimating || _holdController.value > 0) {
      _holdController.reset();
    }
    if (_holdPosition.value != null) {
      _holdPosition.value = null;
    }
  }

  Future<void> _iniciarLiveTracking() async {
    final locationService = ref.read(locationServiceProvider);
    try {
      final initialPos = await locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _initialPosition = LatLng(initialPos.latitude, initialPos.longitude);
        });
        _myPosition.value = _initialPosition;
        _actualizarEtiquetaCiudadSegunUbicacion(_initialPosition!);
      }

      _positionStream = locationService.getLiveLocationStream().listen((
        Position position,
      ) {
        if (mounted) {
          final newPos = LatLng(position.latitude, position.longitude);
          _myPosition.value = newPos;
          _myHeading.value = position.heading;
          if (_seguirUsuario.value) {
            _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
          }
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
    final targetPosition = customPoint ?? _myPosition.value;
    if (targetPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }

    if (customPoint != null && _myPosition.value != null) {
      final distance = Geolocator.distanceBetween(
        _myPosition.value!.latitude,
        _myPosition.value!.longitude,
        customPoint.latitude,
        customPoint.longitude,
      );

      if (distance > 100000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Estás muy lejos de esta ubicación para crear un reporte',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
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

  void _mostrarBuscadorCiudades() {
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

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Buscar Ciudad o Región',
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
                              Navigator.pop(ctx);
                              setState(() {
                                _ciudadSeleccionadaLabel =
                                    '${ciudad.key}, ${region.key}';
                              });
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(region.value, 13),
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
      ),
    );
  }

  Widget _buildMenuChip<T>({
    required String label,
    required T currentValue,
    required List<PopupMenuEntry<T>> items,
    required ValueChanged<T> onSelected,
    required bool isDark,
    bool isSelected = false,
    Color? customColor,
    IconData? icon,
  }) {
    final bgColor = isSelected
        ? (customColor ?? Colors.blueAccent)
        : (isDark ? const Color(0xFF2C2C2C) : Colors.white);
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.grey.shade300 : Colors.grey.shade800);
    final borderColor = isSelected
        ? (customColor ?? Colors.blueAccent)
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return PopupMenuButton<T>(
      initialValue: currentValue,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton(
    IconData icon,
    VoidCallback onTap,
    bool isDark, {
    Color? iconColor,
    bool isLoading = false,
    double size = 50.0,
  }) {
    return Material(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  icon,
                  color:
                      iconColor ?? (isDark ? Colors.white70 : Colors.black87),
                  size: size == 40 ? 20 : 24,
                ),
        ),
      ),
    );
  }

  Set<Marker> _crearMarcadoresGoogle(List<dynamic> reportes) {
    final marcadores = reportes.map((reporte) {
      final urgRaw = reporte.urgencia.toString().toLowerCase();
      final espRaw = (reporte.especie ?? '').toString().toLowerCase();
      String urgKey = 'alta';
      if (urgRaw == 'media') {
        urgKey = 'media';
      } else if (urgRaw == 'baja') {
        urgKey = 'baja';
      }

      String espKey = 'default';
      if (espRaw.contains('perro')) {
        espKey = 'perro';
      } else if (espRaw.contains('gato')) {
        espKey = 'gato';
      } else if (espRaw.contains('silvestre') || espRaw.contains('mapache') || espRaw.contains('tlacuache') || espRaw.contains('ave')) {
        espKey = 'silvestre';
      }

      final icon =
          _customIcons['${urgKey}_$espKey'] ?? BitmapDescriptor.defaultMarker;

      return Marker(
        markerId: MarkerId(reporte.id.toString()),
        position: LatLng(reporte.latitud, reporte.longitud),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        // AQUÍ VA EL CAMBIO 2: zIndex a 10 para los reportes (Siempre quedan encima)
        zIndex: 10,
        onTap: () {
          context.push('/report-detail', extra: reporte).then((_) {
            ref.invalidate(reportesActivosMapaProvider);
            ref.invalidate(miRescateActivoProvider);
          });
        },
      );
    }).toSet();

    if (_myPosition.value != null && _userMarkerIcon != null) {
      marcadores.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: _myPosition.value!,
          icon: _userMarkerIcon!,
          anchor: const Offset(0.5, 0.5),
          // AQUÍ VA EL CAMBIO 3: zIndex a 0 para tu foto de perfil (Queda por debajo de los reportes)
          zIndex: 0, 
          onTap: () {
            final userId = ref.read(authProvider).userId;
            if (userId != null) {
              context.push('/user-info', extra: userId);
            }
          },
        ),
      );
    }
    return marcadores;
  }

  @override
  Widget build(BuildContext context) {
    final reportesAsync = ref.watch(reportesActivosMapaProvider);
    final miRescateAsync = ref.watch(miRescateActivoProvider);

    final bool hasActiveRescue = miRescateAsync.maybeWhen(
      data: (rescate) => rescate != null,
      orElse: () => false,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_lastBrightness != Theme.of(context).brightness) {
      _lastBrightness = Theme.of(context).brightness;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController?.setMapStyle(isDark ? _mapStyleDark : _mapStyleLight);
        }
      });
    }

    if (_initialPosition == null) {
      return const Scaffold(
        extendBody: true,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool cumpleFiltros(dynamic reporte) {
      final pasaUrgencia =
          _filtroUrgencia == 'todos' ||
          reporte.urgencia.toLowerCase() == _filtroUrgencia;
      final especieReporte = (reporte.especie ?? '').toString().toLowerCase();
      bool pasaEspecie = false;
      if (_filtroEspecie == 'todos') {
        pasaEspecie = true;
      } else if (_filtroEspecie == 'perros' &&
          especieReporte.contains('perro')) {
        pasaEspecie = true;
      } else if (_filtroEspecie == 'gatos' && especieReporte.contains('gato')) {
        pasaEspecie = true;
      } else if (_filtroEspecie == 'silvestres' &&
          (especieReporte.contains('silvestre') ||
              especieReporte.contains('mapache') || especieReporte.contains('tlacuache') || especieReporte.contains('ave'))) {
        pasaEspecie = true;
      }

      bool pasaDistancia = true;
      if (_filtroDistancia != 999 && _myPosition.value != null) {
        final dist = Geolocator.distanceBetween(
          _myPosition.value!.latitude,
          _myPosition.value!.longitude,
          reporte.latitud,
          reporte.longitud,
        );
        if (dist > (_filtroDistancia * 1000)) {
          pasaDistancia = false;
        }
      }
      return pasaUrgencia && pasaEspecie && pasaDistancia;
    }

    Color? colorUrgencia;
    if (_filtroUrgencia == 'alta') {
      colorUrgencia = const Color(0xFFD50000); // Rojo intenso
    } else if (_filtroUrgencia == 'media') {
      colorUrgencia = const Color(0xFFFF6D00); // Naranja intenso
    } else if (_filtroUrgencia == 'baja') {
      colorUrgencia = const Color(0xFFFFD600); // Amarillo puro
    }

    final reportesFiltrados = reportesAsync.maybeWhen(
      data: (reportes) => reportes.where(cumpleFiltros).toList(),
      orElse: () => [],
    );

    final marcadores = _crearMarcadoresGoogle(reportesFiltrados);

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style:
                            Theme.of(context).appBarTheme.titleTextStyle
                                ?.copyWith(fontSize: 28) ??
                            const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                        children: const [
                          TextSpan(
                            text: 'Rescue',
                            style: TextStyle(color: Colors.red),
                          ),
                          TextSpan(
                            text: 'Net',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/splash/rescuenet-logo-sinfondo-grande.png',
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.pets, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.pets),
                title: const Text('Reportes Activos'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/reports');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  final userId = ref.read(authProvider).userId;
                  if (userId != null) {
                    context.push('/user-info', extra: userId);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Comunidad'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/community');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/reports', extra: {'initialIndex': 1});
                },
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Contacto a Instituciones'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/institutions');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition!,
                zoom: 18,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              markers: marcadores,
              cameraTargetBounds: CameraTargetBounds(
                LatLngBounds(
                  southwest: const LatLng(14.5321, -118.3651),
                  northeast: const LatLng(32.7187, -86.7125),
                ),
              ),
              minMaxZoomPreference: const MinMaxZoomPreference(4.5, 22.0),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _cameraPosition.value = CameraPosition(
                  target: _initialPosition!,
                  zoom: 18,
                );
                controller.setMapStyle(
                  isDark ? _mapStyleDark : _mapStyleLight,
                );
              },
              onCameraMoveStarted: () {
                if (_seguirUsuario.value) {
                  _seguirUsuario.value = false;
                }
              },
              onCameraMove: (position) {
                _cameraPosition.value = position;
              },
              onTap: (point) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mantén presionado para reportar una emergencia ahí',
                    ),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              onLongPress: (point) {
                _cancelPointer();
                _takePhotoAndNavigate(customPoint: point);
              },
            ),
          ),
          ValueListenableBuilder<Offset?>(
            valueListenable: _holdPosition,
            builder: (context, holdPos, _) {
              if (holdPos == null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: holdPos.dx - 30,
                top: holdPos.dy - 30,
                child: AnimatedBuilder(
                  animation: _holdController,
                  builder: (context, child) {
                    if (!_holdController.isAnimating &&
                        _holdController.value == 0) {
                      return const SizedBox.shrink();
                    }
                    return IgnorePointer(
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
                    );
                  },
                ),
              );
            },
          ),
          Positioned.fill(
            child: reportesAsync.maybeWhen(
              data: (reportes) {
                final radarList = reportes.where(cumpleFiltros).toList();
                return OffScreenMarkers(
                  mapController: _mapController,
                  reportes: radarList,
                  cameraNotifier: _cameraPosition,
                  topMargin: hasActiveRescue ? 220.0 : 150.0,
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSquareButton(
                      Icons.menu_rounded,
                      () => _scaffoldKey.currentState?.openDrawer(),
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _mostrarBuscadorCiudades,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _ciudadSeleccionadaLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSquareButton(
                      Icons.chat_bubble_outline_rounded,
                      () => context.push('/inbox'),
                      isDark,
                      iconColor: const Color.fromARGB(255, 17, 202, 0),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMenuChip<String>(
                        label: _filtroUrgencia == 'todos'
                            ? 'Urgencia'
                            : _filtroUrgencia.toUpperCase(),
                        currentValue: _filtroUrgencia,
                        isSelected: _filtroUrgencia != 'todos',
                        customColor: colorUrgencia,
                        isDark: isDark,
                        onSelected: (val) =>
                            setState(() => _filtroUrgencia = val),
                        items: const [
                          PopupMenuItem(value: 'todos', child: Text('Todos')),
                          PopupMenuItem(
                            value: 'alta',
                            child: Text(
                              'Alta',
                              style: TextStyle(
                                color: Color(0xFFD50000), // Rojo
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'media',
                            child: Text(
                              'Media',
                              style: TextStyle(
                                color: Color(0xFFFF6D00), // Naranja
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'baja',
                            child: Text(
                              'Baja',
                              style: TextStyle(
                                color: Color(0xFFFFD600), // Amarilla
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildMenuChip<String>(
                        label: _filtroEspecie == 'todos'
                            ? 'Especie'
                            : _filtroEspecie.toUpperCase(),
                        currentValue: _filtroEspecie,
                        isSelected: _filtroEspecie != 'todos',
                        isDark: isDark,
                        onSelected: (val) =>
                            setState(() => _filtroEspecie = val),
                        items: const [
                          PopupMenuItem(value: 'todos', child: Text('Todos')),
                          PopupMenuItem(value: 'perros', child: Text('Perro')),
                          PopupMenuItem(value: 'gatos', child: Text('Gato')),
                          PopupMenuItem(
                            value: 'silvestres',
                            child: Text('Silvestre'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildMenuChip<double>(
                        label: _filtroDistancia == 999
                            ? 'Distancia'
                            : '${_filtroDistancia.toInt()} km',
                        currentValue: _filtroDistancia,
                        isSelected: _filtroDistancia != 999,
                        icon: Icons.radar_rounded,
                        isDark: isDark,
                        onSelected: (val) =>
                            setState(() => _filtroDistancia = val),
                        items: const [
                          PopupMenuItem(value: 5.0, child: Text('5 km')),
                          PopupMenuItem(value: 10.0, child: Text('10 km')),
                          PopupMenuItem(value: 20.0, child: Text('20 km')),
                          PopupMenuItem(value: 50.0, child: Text('50 km')),
                          PopupMenuItem(value: 100.0, child: Text('100 km')),
                          PopupMenuItem(value: 999.0, child: Text('Todos')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          miRescateAsync.maybeWhen(
            data: (rescate) {
              if (rescate == null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: MediaQuery.of(context).padding.top + 130,
                left: 16,
                right: 16,
                child: ActiveRescueCard(rescate: rescate),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Positioned(
            bottom: 90,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                reportesAsync.maybeWhen(
                  loading: () => _buildSquareButton(
                    Icons.refresh,
                    () {},
                    isDark,
                    isLoading: true,
                    size: 40.0,
                  ),
                  orElse: () => _buildSquareButton(
                    Icons.refresh_rounded,
                    _refrescarMapaManual,
                    isDark,
                    iconColor: Colors.blueAccent,
                    size: 40.0,
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: _seguirUsuario,
                  builder: (context, seguir, _) {
                    return FloatingActionButton(
                      heroTag: 'my_location_btn',
                      mini: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: seguir
                          ? (isDark
                                ? Colors.blue.shade900
                                : Colors.blue.shade50)
                          : (isDark ? Colors.grey.shade800 : Colors.white),
                      foregroundColor: seguir
                          ? (isDark
                                ? Colors.blueAccent.shade100
                                : Colors.blueAccent)
                          : Colors.grey,
                      elevation: 4,
                      onPressed: () {
                        _seguirUsuario.value = true;
                        if (_myPosition.value != null) {
                          _actualizarEtiquetaCiudadSegunUbicacion(
                            _myPosition.value!,
                          );
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(_myPosition.value!, 18),
                          );
                        }
                      },
                      child: const Icon(Icons.my_location),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}