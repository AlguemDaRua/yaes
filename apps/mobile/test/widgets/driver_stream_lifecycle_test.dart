import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/driver/components/driver_idle_panels.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_trip_repository.dart';

void main() {
  testWidgets('reusing a cancelled Firebase-style stream builds an error box', (
    tester,
  ) async {
    // FlutterFire Android's observe() is async*: its outer stream accepts
    // one listener, even though its internal native EventChannel is broadcast.
    final controller = StreamController<bool>();
    final isOnTrip = ValueNotifier(false);
    addTearDown(controller.close);
    addTearDown(isOnTrip.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: isOnTrip,
            builder: (context, onTrip, _) => Stack(
              children: [
                if (!onTrip)
                  Positioned(
                    top: 100,
                    left: 15,
                    right: 15,
                    child: StreamBuilder<bool>(
                      stream: controller.stream,
                      builder: (context, snapshot) => const Text('Painel'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    isOnTrip.value = true;
    await tester.pump();
    isOnTrip.value = false;
    await tester.pump();

    expect(
      tester.takeException(),
      isA<StateError>().having(
        (error) => error.message,
        'message',
        contains('Stream has already been listened to'),
      ),
    );
    expect(find.byType(ErrorWidget), findsOneWidget);
  });

  for (final status in ['completed', 'cancelled']) {
    testWidgets('idle panels resubscribe safely after repeated $status trips', (
      tester,
    ) async {
      final fixture = await _mountPanels(tester);
      expect(find.text('Agenda'), findsOneWidget);
      expect(
        find.text('Online • elegível para receber pedidos'),
        findsOneWidget,
      );

      for (var cycle = 0; cycle < 2; cycle++) {
        fixture.state.restoreActiveTrip('trip-$cycle', {'status': 'started'});
        await tester.pumpAndSettle();
        expect(find.byType(DriverIdlePanels), findsNothing);
        expect(fixture.repository.cancelledQueries, cycle + 1);
        expect(fixture.connectionCancellations, cycle + 1);

        // Exercise DriverState's actual terminal-status listener.
        fixture.repository.tripEvents.add({'status': status});
        await tester.pumpAndSettle();

        expect(fixture.state.isOnTrip, isFalse);
        expect(find.text('Agenda'), findsOneWidget);
        expect(
          find.text('Online • elegível para receber pedidos'),
          findsOneWidget,
        );
        expect(fixture.repository.queries.length, cycle + 2);
        expect(fixture.connections.length, cycle + 2);
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
      }
    });
  }

  testWidgets('location rebuilds retain listeners and still receive updates', (
    tester,
  ) async {
    final fixture = await _mountPanels(tester);

    for (var update = 0; update < 3; update++) {
      fixture.state.setCurrentLocation(LatLng(-25.97 + update * 0.001, 32.57));
      await tester.pumpAndSettle();
    }
    expect(fixture.repository.queries, hasLength(1));
    expect(fixture.connections, hasLength(1));

    fixture.connections.single.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('A reconectar ao servidor…'), findsOneWidget);
    fixture.connections.single.add(true);
    fixture.repository.queries.single.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Agenda'), findsNothing);
    expect(find.text('Online • elegível para receber pedidos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _PanelRepository extends FakeTripRepository {
  final queries = <StreamController<List<Map<String, dynamic>>>>[];
  final tripEvents = StreamController<Map<String, dynamic>?>.broadcast();
  int cancelledQueries = 0;

  @override
  Stream<List<Map<String, dynamic>>> readTripsByDriver(String uid) {
    late final StreamController<List<Map<String, dynamic>>> controller;
    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () => controller.add([
        {'tripType': 'scheduled', 'status': 'pending'},
      ]),
      onCancel: () => cancelledQueries++,
    );
    queries.add(controller);
    return controller.stream;
  }

  @override
  Stream<Map<String, dynamic>?> watchTrip(String tripId) => tripEvents.stream;

  Future<void> close() async {
    for (final query in queries) {
      await query.close();
    }
    await tripEvents.close();
  }
}

class _PanelFixture {
  final repository = _PanelRepository();
  final auth = FakeAuthRepository()..setUser(AppUser(uid: 'driver-test'));
  final connections = <StreamController<bool>>[];
  late final state = DriverState(repository: repository, auth: auth);
  int connectionCancellations = 0;

  Stream<bool> watchConnection() {
    late final StreamController<bool> controller;
    controller = StreamController<bool>(
      onListen: () => controller.add(true),
      onCancel: () => connectionCancellations++,
    );
    connections.add(controller);
    return controller.stream;
  }

  Future<void> close() async {
    state.dispose();
    await repository.close();
    for (final connection in connections) {
      await connection.close();
    }
  }
}

Future<_PanelFixture> _mountPanels(WidgetTester tester) async {
  final fixture = _PanelFixture();
  fixture.state.setCurrentLocation(const LatLng(-25.97, 32.57));
  fixture.state.setIsOnline(true);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.close();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ITripRepository>.value(value: fixture.repository),
        Provider<IAuthRepository>.value(value: fixture.auth),
        ChangeNotifierProvider<DriverState>.value(value: fixture.state),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Consumer<DriverState>(
              builder: (context, state, _) => Stack(
                children: [
                  if (!state.isOnTrip)
                    Positioned.fill(
                      child: DriverIdlePanels(
                        watchConnection: fixture.watchConnection,
                        onRouteRequested: () {},
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}
