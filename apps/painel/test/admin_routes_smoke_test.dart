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
  testWidgets('admin routes render without Flutter errors', (tester) async {
    await initializeDateFormatting('pt_PT');
    authNotifier.setRoleForTest(UserRole.admin);

    final routes = [
      '/admin/dashboard',
      '/admin/partners',
      '/admin/partners/PAR-001',
      '/admin/drivers',
      '/admin/drivers/DRV-001',
      '/admin/vehicles',
      '/admin/cars/CAR-001',
      '/admin/documents',
      '/admin/fleets',
      '/admin/fleets/FLT-001',
      '/admin/trips',
      '/admin/trips/live',
      '/admin/trips/TRP-2847A',
      '/admin/users',
      '/admin/users/USR-001',
      '/admin/finance',
      '/admin/commissions',
      '/admin/commissions/list',
      '/admin/pricing',
      '/admin/notifications',
      '/admin/alerts',
      '/admin/audit',
      '/admin/reports',
      '/admin/settings',
    ];

    final viewports = {
      'phone': const Size(390, 844),
      'tablet': const Size(768, 900),
      'desktop': const Size(1440, 900),
    };

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final viewport in viewports.entries) {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1;
      appRouter.go('/admin/dashboard');
      await tester.pumpWidget(const ProviderScope(child: YaApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (final route in routes) {
        appRouter.go(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final exception = tester.takeException();
        if (exception != null) {
          final details = exception is FlutterError
              ? [
                  exception.toStringDeep(),
                  for (final node in exception.diagnostics) node.toStringDeep(),
                ].join('\n')
              : exception.toString();
          fail('Route failed at ${viewport.key} ${viewport.value}: $route\n'
              '$details');
        }
      }
    }
  });
}
