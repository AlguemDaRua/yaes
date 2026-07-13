import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ya_painel/main.dart';
import 'package:ya_painel/router/app_router.dart';

void main() {
  testWidgets('map live zoom controls update map zoom', (tester) async {
    await initializeDateFormatting('pt_PT');
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();

    appRouter.go('/admin/trips/live');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final mapContext = tester.element(find.byType(TileLayer));
    final initialZoom = MapCamera.of(mapContext).zoom;

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pump();

    final zoomedIn = MapCamera.of(mapContext).zoom;
    expect(zoomedIn, greaterThan(initialZoom));

    await tester.tap(find.byIcon(LucideIcons.minus));
    await tester.pump();

    final zoomedOut = MapCamera.of(mapContext).zoom;
    expect(zoomedOut, closeTo(initialZoom, 0.001));
  });
}
