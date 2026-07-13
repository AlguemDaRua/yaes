import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/controllers/route_controller.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_trip_repository.dart';

// ─── Fake AnimatedMapController ─────────────────────────────────────────────

class _FakeAnimatedMapController extends AnimatedMapController {
  _FakeAnimatedMapController()
      : super(vsync: const _TestVsync());

  @override
  Future<void> animatedFitCamera({
    required CameraFit cameraFit,
    Curve? curve,
    String? customId,
    double? rotation,
    Duration? duration,
    bool? cancelPreviousAnimations,
  }) async {
    // no-op: map fitting is not tested here
  }
}

class _TestVsync implements TickerProvider {
  const _TestVsync();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

// ─── Minimal route data ──────────────────────────────────────────────────────

List<Map<String, dynamic>> _twoRoutes() => [
      {
        'points': [const LatLng(-25.96, 32.57), const LatLng(-25.97, 32.58)],
        'distance': '1.00',
        'duration': '2.0',
      },
      {
        'points': [const LatLng(-25.96, 32.57), const LatLng(-25.98, 32.60)],
        'distance': '5.50',
        'duration': '10.0',
      },
    ];

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late PassengerState appState;
  late _FakeAnimatedMapController mapController;

  setUp(() {
    appState = PassengerState(
        repository: FakeTripRepository(),
        auth: FakeAuthRepository(),
        simulateLoading: false);
    mapController = _FakeAnimatedMapController();
  });

  tearDown(() {
    mapController.dispose();
    appState.dispose();
  });

  // Helper: builds a RouteController with a valid BuildContext from the widget tree.
  Widget scaffold(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  // ── Guard conditions (no HTTP, no context needed) ─────────────────────────

  group('calculateRoute guard conditions', () {
    test('does nothing when fromAddress is empty', () async {
      appState.toAddress = 'Destination';
      appState.destinationLocation = const LatLng(-25.97, 32.58);
      appState.originLocation = const LatLng(-25.96, 32.57);

      late RouteController ctrl;
      int notifyCount = 0;

      // contextGetter will never be called because the guard returns early
      ctrl = RouteController(
        appState: appState,
        animatedMapController: mapController,
        token: 'fake-token',
        contextGetter: () => throw StateError('context should not be called'),
      );
      ctrl.addListener(() => notifyCount++);

      ctrl.calculateRoute();
      await Future.delayed(Duration.zero);

      expect(notifyCount, 0);
      expect(ctrl.allRoutes, isEmpty);
    });

    test('does nothing when toAddress is empty', () async {
      appState.fromAddress = 'Origin';
      appState.originLocation = const LatLng(-25.96, 32.57);

      final ctrl = RouteController(
        appState: appState,
        animatedMapController: mapController,
        token: 'fake-token',
        contextGetter: () => throw StateError('context should not be called'),
      );

      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      ctrl.calculateRoute();
      await Future.delayed(Duration.zero);

      expect(notifyCount, 0);
    });

    test('does nothing when originLocation is null', () async {
      appState.fromAddress = 'Origin';
      appState.toAddress = 'Destination';
      appState.destinationLocation = const LatLng(-25.97, 32.58);

      final ctrl = RouteController(
        appState: appState,
        animatedMapController: mapController,
        token: 'fake-token',
        contextGetter: () => throw StateError('context should not be called'),
      );

      ctrl.calculateRoute();
      await Future.delayed(Duration.zero);

      expect(ctrl.allRoutes, isEmpty);
    });
  });

  // ── selectRoute (needs a real BuildContext for _fitRouteBounds) ──────────

  group('selectRoute', () {
    test('does nothing when allRoutes is empty', () {
      final ctrl = RouteController(
        appState: appState,
        animatedMapController: mapController,
        token: 'fake-token',
        contextGetter: () => throw StateError('should not be reached'),
      );

      ctrl.selectRoute(); // must not throw
      expect(ctrl.selectedRouteIndex, 0);
    });

    testWidgets('cycles index and wraps around to 0', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(scaffold(
        Builder(builder: (ctx) {
          capturedContext = ctx;
          return const SizedBox.shrink();
        }),
      ));

      final ctrl = RouteController(
        appState: appState,
        animatedMapController: mapController,
        token: 'fake-token',
        contextGetter: () => capturedContext,
      );
      ctrl.allRoutes = _twoRoutes();
      ctrl.routePoints = ctrl.allRoutes[0]['points'];

      ctrl.selectRoute();
      expect(ctrl.selectedRouteIndex, 1);

      ctrl.selectRoute();
      expect(ctrl.selectedRouteIndex, 0); // wrapped
    });

    testWidgets('updates appState distanceKm and durationMin', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(scaffold(
        Builder(builder: (ctx) {
          capturedContext = ctx;
          return const SizedBox.shrink();
        }),
      ));

      final ctrl = RouteController(
        appState: appState,
        animatedMapController: mapController,
        token: 'fake-token',
        contextGetter: () => capturedContext,
      );
      ctrl.allRoutes = _twoRoutes();
      ctrl.routePoints = ctrl.allRoutes[0]['points'];

      ctrl.selectRoute(); // selects index 1: distance=5.50, duration=10.0

      expect(appState.distanceKm, 5.5);
      expect(appState.durationMin, 10);
    });

    testWidgets('fires notifyListeners on selectRoute', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(scaffold(
        Builder(builder: (ctx) {
          capturedContext = ctx;
          return const SizedBox.shrink();
        }),
      ));

      final ctrl = RouteController(
        appState: appState,
        animatedMapController: mapController,
        token: 'fake-token',
        contextGetter: () => capturedContext,
      );
      ctrl.allRoutes = _twoRoutes();
      ctrl.routePoints = ctrl.allRoutes[0]['points'];

      int notifyCount = 0;
      ctrl.addListener(() => notifyCount++);

      ctrl.selectRoute();

      expect(notifyCount, 1);
    });
  });
}
