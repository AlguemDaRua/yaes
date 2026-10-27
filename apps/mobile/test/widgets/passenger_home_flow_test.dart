import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/models/cardata.dart';
import 'package:limousineexecutive/passenger/widgets/car_type_selector.dart';
import 'package:limousineexecutive/services/pricing_service.dart';
import 'package:provider/provider.dart';
import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_trip_repository.dart';

void main() {
  late PassengerState state;
  final capture = Platform.environment['YA_CAPTURE_PREVIEWS'] == '1';
  final previewKey = GlobalKey();

  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (capture && root != null) {
      final font = FontLoader('Roboto');
      for (final weight in ['regular', 'bold']) {
        font.addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      }
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await icons.load();
    }
  });

  setUp(() {
    state = PassengerState(
      repository: FakeTripRepository(),
      auth: FakeAuthRepository(),
      simulateLoading: false,
    );
  });
  tearDown(() => state.dispose());

  void route() {
    state.fromAddress = 'Praça da Independência';
    state.toAddress = 'Universidade Eduardo Mondlane';
    state.originLocation = const LatLng(-25.97, 32.57);
    state.destinationLocation = const LatLng(-25.95, 32.60);
  }

  Future<void> mount(WidgetTester tester, {double width = 390}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: previewKey,
              child: ColoredBox(
                color: const Color(0xFFE7ECE4),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  // O seletor de tipo de carro obtém as categorias através do seu provider/serviço interno
                  child: CarTypeSelector(
                    onTripRequested: () async {},
                    onRouteChanged: () {},
                    onStopRequested: () {},
                    onAnimateSheet: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final asset in CarData.categoryImages.values) {
        await precacheImage(AssetImage(asset), previewKey.currentContext!);
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> preview(WidgetTester tester, String name) async {
    if (!capture) return;
    final boundary =
        previewKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('route is required before transport selection', (tester) async {
    await mount(tester);
    expect(find.text('Moto'), findsNothing);
    await tester.tap(find.text('Escolher transporte'));
    await tester.pumpAndSettle();
    expect(find.text('Moto'), findsNothing);
    await preview(tester, 'passenger-route');

    route();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher transporte'));
    await tester.pumpAndSettle();
    for (final category in parseCarCategories(null)) {
      expect(find.text(category.label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    await preview(tester, 'passenger-categories');
    await tester.ensureVisible(find.text('Moto'));
    await tester.tap(find.text('Moto'));
    await tester.pumpAndSettle();
    expect(state.carCategory, 'moto');
  });

  testWidgets('cards fit a small phone', (tester) async {
    route();
    await mount(tester, width: 320);
    await tester.tap(find.text('Escolher transporte'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Txopela'));
    await tester.tap(find.text('Txopela'));
    expect(state.carCategory, 'txopela');
  });

  test('editing a location clears selection but preserves stops', () {
    state.selectCategory('moto', 'Moto', 3);
    expect(state.selectedCarType, isEmpty);
    route();
    state.addStop({'name': 'Paragem A'});
    state.selectCategory('txopela', 'Txopela', 2);
    expect(state.carCategory, 'txopela');
    state.destinationLocation = null;
    expect(state.hasTripLocations, isFalse);
    expect(state.selectedCarType, isEmpty);
    expect(state.stops.single['name'], 'Paragem A');
  });
}
