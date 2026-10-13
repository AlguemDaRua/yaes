import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/shared/widgets/map_compass_button.dart';

void main() {
  Widget buildTestableWidget({
    MapController? mapController,
    AnimatedMapController? animatedMapController,
    double initialRotation = 45.0,
    bool autoHide = false,
    VoidCallback? onReset,
  }) {
    final effectiveMapController =
        animatedMapController?.mapController ?? mapController ?? MapController();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: effectiveMapController,
                options: MapOptions(
                  initialCenter: const LatLng(0, 0),
                  initialZoom: 10,
                  initialRotation: initialRotation,
                ),
                children: const [],
              ),
              MapCompassButton(
                mapController: mapController,
                animatedMapController: animatedMapController,
                autoHide: autoHide,
                onReset: onReset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renders MapCompassButton and rotates needle', (tester) async {
    final controller = MapController();

    await tester.pumpWidget(buildTestableWidget(mapController: controller));
    await tester.pumpAndSettle();

    expect(find.byType(MapCompassButton), findsOneWidget);
    expect(find.byTooltip('Apontar a norte'), findsOneWidget);
  });

  testWidgets('tapping MapCompassButton resets rotation to North (0°)', (tester) async {
    final controller = MapController();
    var resetCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        mapController: controller,
        initialRotation: 60.0,
        onReset: () => resetCalled = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.camera.rotation, closeTo(60.0, 0.1));

    await tester.tap(find.byType(MapCompassButton));
    await tester.pumpAndSettle();

    expect(resetCalled, isTrue);
    expect(controller.camera.rotation, closeTo(0.0, 0.1));
  });

  testWidgets('autoHide hides button when rotation is 0° and shows when rotated', (tester) async {
    final controller = MapController();

    await tester.pumpWidget(
      buildTestableWidget(
        mapController: controller,
        initialRotation: 0.0,
        autoHide: true,
      ),
    );
    await tester.pumpAndSettle();

    final animatedOpacityFinder = find.byType(AnimatedOpacity);
    expect(animatedOpacityFinder, findsOneWidget);
    final animatedOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
    expect(animatedOpacity.opacity, equals(0.0));

    // Now rotate the map
    controller.rotate(45.0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final updatedOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
    expect(updatedOpacity.opacity, equals(1.0));
  });

  testWidgets('tapping MapCompassButton when already at 0° triggers onReset without animation error', (tester) async {
    final controller = MapController();
    var resetCalled = false;

    await tester.pumpWidget(
      buildTestableWidget(
        mapController: controller,
        initialRotation: 0.0,
        onReset: () => resetCalled = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MapCompassButton));
    await tester.pumpAndSettle();

    expect(resetCalled, isTrue);
    expect(controller.camera.rotation, closeTo(0.0, 0.1));
  });

  testWidgets('works when providing only animatedMapController', (tester) async {
    late final AnimatedMapController animController;

    await tester.pumpWidget(
      TestAnimatedMapControllerHost(
        builder: (context, controller) {
          animController = controller;
          return buildTestableWidget(
            animatedMapController: controller,
            initialRotation: 30.0,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MapCompassButton), findsOneWidget);
    expect(animController.mapController.camera.rotation, closeTo(30.0, 0.1));

    await tester.tap(find.byType(MapCompassButton));
    await tester.pumpAndSettle();

    expect(animController.mapController.camera.rotation, closeTo(0.0, 0.1));
  });
}

class TestAnimatedMapControllerHost extends StatefulWidget {
  final Widget Function(BuildContext context, AnimatedMapController controller) builder;

  const TestAnimatedMapControllerHost({super.key, required this.builder});

  @override
  State<TestAnimatedMapControllerHost> createState() => _TestAnimatedMapControllerHostState();
}

class _TestAnimatedMapControllerHostState extends State<TestAnimatedMapControllerHost>
    with TickerProviderStateMixin {
  late final AnimatedMapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimatedMapController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
