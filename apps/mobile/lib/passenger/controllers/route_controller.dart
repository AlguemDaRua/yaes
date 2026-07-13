import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/services/location_service.dart';

class RouteController extends ChangeNotifier {
  final PassengerState appState;
  final AnimatedMapController animatedMapController;
  final String token;
  final BuildContext Function() contextGetter;

  List<LatLng> routePoints = [];
  List<LatLng> animatedRoutePoints = [];
  List<Map<String, dynamic>> allRoutes = [];
  int selectedRouteIndex = 0;
  
  TickerProvider? _vsync;
  AnimationController? _animationController;

  RouteController({
    required this.appState,
    required this.animatedMapController,
    required this.token,
    required this.contextGetter,
    TickerProvider? vsync,
  }) : _vsync = vsync;

  void setVsync(TickerProvider vsync) {
    _vsync = vsync;
  }

  void _startAnimation() {
    if (_vsync == null) {
      // No ticker: just show the full route. Callers notify listeners after
      // calling _startAnimation, so we avoid a redundant notification here.
      animatedRoutePoints = routePoints;
      return;
    }

    _animationController?.dispose();
    _animationController = AnimationController(
      vsync: _vsync!,
      duration: const Duration(milliseconds: 1500),
    );

    final Animation<double> animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.fastOutSlowIn,
    );

    _animationController!.addListener(() {
      _updateAnimatedPoints(animation.value);
    });

    _animationController!.forward();
  }

  void _updateAnimatedPoints(double progress) {
    if (routePoints.isEmpty) return;
    
    final int targetCount = (routePoints.length * progress).floor();
    if (targetCount <= 1) {
      animatedRoutePoints = routePoints.take(1).toList();
    } else {
      animatedRoutePoints = routePoints.take(targetCount).toList();
    }
    notifyListeners();
  }

  void calculateRoute() async {
    if (appState.fromAddress.isEmpty ||
        appState.toAddress.isEmpty ||
        appState.destinationLocation == null ||
        appState.originLocation == null) {
      return;
    }

    final origin = appState.originLocation;
    final destination = appState.destinationLocation;

    if (origin == null || destination == null) return;

    try {
      final routes = await LocationService.fetchRoutesAlternatives(
        origin: origin,
        destination: destination,
        token: token,
        stops: appState.stops,
      );

      appState.destinationLocation = destination;
      allRoutes = routes;
      selectedRouteIndex = 0;
      routePoints = routes[0]['points'];
      
      // Start path animation
      _startAnimation();

      appState.distanceKm = double.parse(routes[0]['distance']);
      appState.durationMin = double.parse(routes[0]['duration']).round();
      appState.showRoute = true;
      notifyListeners();

      // Fetch server-side price in background after route is loaded
      appState.fetchServerPrice();

      // Centralizar a rota principal
      _fitRouteBounds();
    } catch (e) {
      debugPrint('Route calculation failed: $e');
    }
  }

  void selectRoute() {
    int index = selectedRouteIndex + 1;
    if (allRoutes.isEmpty || index < 0) return;
    if (index >= allRoutes.length) {
      index = 0;
    }

    selectedRouteIndex = index;
    routePoints = allRoutes[index]['points'];
    
    // Start animation for the new selected route
    _startAnimation();

    appState.distanceKm = double.parse(allRoutes[index]['distance']);
    appState.durationMin = double.parse(allRoutes[index]['duration']).round();
    notifyListeners();

    _fitRouteBounds();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _fitRouteBounds() {
    final context = contextGetter();
    final bounds = LatLngBounds.fromPoints(routePoints);

    animatedMapController.animatedFitCamera(
      cameraFit: CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          right: 50,
          left: 50,
          bottom: (MediaQuery.of(context).size.height / 2),
        ),
      ),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }
}
