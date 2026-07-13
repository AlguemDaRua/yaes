import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ya_painel/core/auth/auth_provider.dart';
import 'package:ya_painel/core/auth/auth_user.dart';
import 'package:ya_painel/main.dart';
import 'package:ya_painel/router/app_router.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT');
  });

  testWidgets('admin flow opens partner list, detail and trip detail',
      (tester) async {
    authNotifier.setRoleForTest(UserRole.admin);
    _setDesktopViewport(tester);

    appRouter.go('/admin/dashboard');
    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (final route in <String>[
      '/admin/partners',
      '/admin/partners/PAR-001',
      '/admin/trips/TRP-2847A',
    ]) {
      appRouter.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      _expectNoFlutterException(tester, route);
      expect(appRouter.routeInformationProvider.value.uri.toString(), route);
    }
  });

  testWidgets('partner flow opens dashboard, fleet, earnings and alerts',
      (tester) async {
    authNotifier.setRoleForTest(UserRole.partner);
    _setDesktopViewport(tester);

    appRouter.go('/partner/dashboard');
    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    for (final route in <String>[
      '/partner/dashboard',
      '/partner/fleet',
      '/partner/earnings',
      '/partner/alerts',
    ]) {
      appRouter.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      _expectNoFlutterException(tester, route);
      expect(appRouter.routeInformationProvider.value.uri.toString(), route);
    }
  });
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    authNotifier.setRoleForTest(UserRole.admin);
  });
}

void _expectNoFlutterException(WidgetTester tester, String route) {
  final exception = tester.takeException();
  if (exception == null) return;

  final details = exception is FlutterError
      ? <String>[
          exception.toStringDeep(),
          for (final node in exception.diagnostics) node.toStringDeep(),
        ].join('\n')
      : exception.toString();

  fail('Route failed: $route\n$details');
}
