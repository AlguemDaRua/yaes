import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:limousineexecutive/driver/components/agenda_box.dart';
import 'package:limousineexecutive/driver/components/buttons/zoom_buttons.dart';
import 'package:limousineexecutive/driver/components/dialogs/exit_app_dialog.dart';
import 'package:limousineexecutive/driver/components/top_bar.dart';
import 'package:limousineexecutive/driver/components/on_trip_modal.dart';
import 'package:limousineexecutive/driver/components/ring_modal.dart';
import 'package:limousineexecutive/driver/components/vehicle_marker.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/passenger/components/map_util/pointer_destination.dart';
import 'package:limousineexecutive/services/location_service.dart';
import 'package:limousineexecutive/services/messaging_service.dart';
import 'package:limousineexecutive/utils/app_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage>
    with TickerProviderStateMixin {
  // late MapController _mapController; // controladora do mapa
  late final AnimatedMapController _animatedMapController;

  StreamSubscription<Position>? _positionStream; // position stream
  List<LatLng> _routePoints = []; // Current route points
  List<Map<String, dynamic>> _allRoutes = []; // all alternative routes
  String token = AppConfig.mapboxToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation(context);
      MessagingService.onLogin(); // Ensure token is saved when driver enters the page
      final appState = Provider.of<DriverState>(context, listen: false);
      appState.startWalletWatch();
      MessagingService.onNewTripReceived = (tripId) {
        debugPrint("NEW TRIP RECEIVED: $tripId, online: ${appState.isOnline}");
        if (appState.isOnline) {
          appState.handleNewTripRequest(tripId);
        }
      };
    });
    _animatedMapController = AnimatedMapController(vsync: this);

    startTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _animatedMapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation(BuildContext context) async {
    final appState = Provider.of<DriverState>(context, listen: false);

    // 1. Check and request location permission
    var status = await Permission.location.request();
    if (!context.mounted) return;

    if (status.isDenied || status.isPermanentlyDenied) {
      // user denied

      // Show alert
      await showDialog(
        context: context,

        builder: (_) => AlertDialog(
          title: const Text("Permissão para localização negada"),
          content: const Text(
            "Para continuar, conceda a permissão nas configurações do seu dispositivo.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Open location settings
                await openAppSettings();
                return;
              },
              child: const Text("Abrir Configurações"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                return;
              },
              child: const Text("Cancelar"),
            ),
          ],
        ),
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    appState.setCurrentLocation(LatLng(position.latitude, position.longitude));
    debugPrint('$position');
    appState.setAngle(position.heading);
    if (appState.currentLocation != null && mounted) {
      setState(() {
        _animatedMapController.animateTo(
          dest: appState.currentLocation!,
          zoom: 14,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _calculateRouteToOrigin() async {
    final appState = Provider.of<DriverState>(context, listen: false);

    final origin = appState.currentLocation;
    final destination = appState.originLocation;

    if (origin == null || destination == null) return;

    try {
      List<Map<String, dynamic>> routes =
          await LocationService.fetchRoutesAlternatives(
            origin: origin,
            destination: destination,
            token: token,
          );

      if (mounted) {
        setState(() {
          _allRoutes = routes;
          _routePoints = routes[0]['points'];
          appState.setShowRoute(true);
        });

        _animatedMapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(_routePoints),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              right: 50.w,
              left: 50.w,
              bottom: 350.sp,
            ),
          ),
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      debugPrint("Erro ao calcular rotas: $e");
    }
  }

  void _calculateRouteToDestination() async {
    final appState = Provider.of<DriverState>(context, listen: false);

    final origin = appState.originLocation;
    final destination = appState.destinationLocation;

    if (origin == null || destination == null) return;

    try {
      List<Map<String, dynamic>> routes =
          await LocationService.fetchRoutesAlternatives(
            origin: origin,
            destination: destination,
            token: token,
          );

      if (mounted) {
        setState(() {
          _allRoutes = routes;
          _routePoints = routes[0]['points'];
          appState.setShowRoute(true);
        });

        _animatedMapController.animatedFitCamera(
          cameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(_routePoints),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              right: 50.w,
              left: 50.w,
              bottom: 260.sp,
            ),
          ),
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      debugPrint("Erro ao calcular rotas: $e");
    }
  }

  void startTracking() {
    final appState = Provider.of<DriverState>(context, listen: false);
    _positionStream = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1, // More precise tracking for navigation
          ),
        ).listen((Position position) {
          final novaPosicao = LatLng(position.latitude, position.longitude);
          
          double angulo = 0;
          if (position.heading != 0) {
            angulo = position.heading * pi / 180;
          } else if (appState.currentLocation != null) {
            // Fallback: calculate angle from previous point
            final prev = appState.currentLocation!;
            angulo = _calculateBearing(prev, novaPosicao);
          }

          appState.updateVehicle(novaPosicao, angulo);

          // _mapController.move(novaPosicao, _mapController.camera.zoom);

          _animatedMapController.animateTo(
            dest: novaPosicao,
            zoom: _animatedMapController.mapController.camera.zoom,
            duration: const Duration(seconds: 1),
            curve: Curves.linear,
          );
        });
  }

  // STOP TRACKING
  void stopTracking() {
    _positionStream?.cancel();
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    return atan2(y, x);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<DriverState>(context);

    if (appState.isOnTrip && !appState.isTripStarted && _routePoints.isEmpty) {
      _calculateRouteToOrigin();
    }

    if (!appState.isOnTrip && _routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _routePoints = [];
            _allRoutes = [];
          });
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // go back one route
          return;
        }
        showExitAppDialog(context);
      },

      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            /// MAP
            FlutterMap(
              mapController: _animatedMapController.mapController,
              options: MapOptions(
                onTap: (_, __) => FocusScope.of(context).unfocus(),
                initialCenter:
                    appState.currentLocation ?? const LatLng(-25.9692, 32.5732),
                initialZoom: 14,
                minZoom: 10, // minimum zoom out limit
                maxZoom: 18, // maximum zoom in limit
                initialRotation: 0,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom | // simple zoom
                      InteractiveFlag.drag | // map pan
                      InteractiveFlag.doubleTapZoom, // double tap zoom
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token",
                  subdomains: ['a', 'b', 'c'],
                ),

                if (appState.showRoute && _routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: List.generate(_allRoutes.length, (i) {
                      return Polyline(
                        points: List<LatLng>.from(_allRoutes[i]['points']),
                        strokeWidth: 5.0,
                        color: Colors.grey,
                      );
                    }),
                  ),
                // Selected route
                if (appState.showRoute && _routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.0,
                        // color: Colors.blue,
                        gradientColors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ],
                  ),

                AnimatedMarkerLayer(
                  markers: [
                    // Vehicle marker
                    if (appState.currentLocation != null)
                      AnimatedMarker(
                        point: appState.currentLocation!, // Always follow current position
                        width: 50.w,
                        height: 50.h,
                        duration: const Duration(milliseconds: 1000), // Matched with map animation
                        curve: Curves.linear, // Linear for smoother continuous movement
                        builder: (context, animation) {
                          return VehicleMarker(
                            angle: appState.vehicleAngle,
                            size: 40,
                          );
                        },
                      ),
                  ],
                ),

                MarkerLayer(
                  markers: [
                    // Passenger trip destination marker
                    if (appState.showRoute &&
                        appState.isTripStarted &&
                        appState.destinationLocation != null)
                      Marker(
                        alignment: Alignment.topCenter,
                        width: 120.sp,
                        point: appState.destinationLocation!,
                        child: buildDestinationMarker(minutes: 18),
                      ),

                    // Destination marker to passenger
                    if (appState.showRoute &&
                        !appState.isTripStarted &&
                        appState.originLocation != null)
                      Marker(
                        alignment: Alignment.topCenter,
                        width: 120.sp,
                        point: appState.originLocation!,
                        child: buildDestinationMarker(minutes: 10),
                      ),
                  ],
                ),
              ],
            ),

            // Zoom buttons centered on the right side
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 15.sp, bottom: 50.sp),
                child: ZoomButtons(
                  onZoomIn: () {
                    final currentZoom =
                        _animatedMapController.mapController.camera.zoom;

                    if (currentZoom <= 17.5) {
                      _animatedMapController.animateTo(
                        dest:
                            _animatedMapController.mapController.camera.center,
                        zoom: currentZoom + 0.5, // increase zoom
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                      // zoom in logic
                    }
                  },
                  onZoomOut: () {
                    final currentZoom =
                        _animatedMapController.mapController.camera.zoom;

                    if (currentZoom >= 12.5) {
                      _animatedMapController.animateTo(
                        dest:
                            _animatedMapController.mapController.camera.center,
                        zoom: currentZoom - 0.5, // decrease zoom
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }

                    // zoom out logic
                  },
                ),
              ),
            ),

            if (!appState.isOnTrip)
              /// Top buttons and driver status (Online/offline)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10.sp,
                left: 15.sp,
                right: 15.sp,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TopBar(onTap: () => _calculateRouteToOrigin()),
                      ),
                    ],
                  ),
                ),
              ),

            if (!appState.isOnTrip)
              // Daily earnings and schedule
              Positioned(
                left: 15.sp,
                right: 15.sp,
                top: MediaQuery.of(context).padding.top + 100.sp,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: const Row(children: [AgendaBox()]),
                ),
              ),

            // Trip ring modal when driver is online and phone is ringing
            if (appState.isOnline && appState.isRinging)
              const Align(alignment: Alignment.bottomCenter, child: RingModal()),

            if (appState.isOnTrip)
              Align(
                alignment: Alignment.bottomCenter,
                child: GoingToPassenger(
                  onTap: () => _calculateRouteToDestination(),
                ),
              ),

            /// Loading overlay (only while _currentLocation is null)
            if (appState.currentLocation == null)
              Container(
                color: Colors.white.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "A localizar-te...",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 20.sp),
                      CircularProgressIndicator(
                        color: Colors.amber.withValues(alpha: 0.59),
                        strokeWidth: 3.sp,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
