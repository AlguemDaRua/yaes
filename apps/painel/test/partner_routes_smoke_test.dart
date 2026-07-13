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
  testWidgets('partner routes render without Flutter errors', (tester) async {
    await initializeDateFormatting('pt_PT');
    authNotifier.setRoleForTest(UserRole.partner);

    final List<String> routes = <String>[
      '/partner',
      '/partner/dashboard',
      '/partner/fleet',
      '/partner/fleet/driver/DRV-001',
      '/partner/fleet/vehicle/VEH-001',
      '/partner/drivers',
      '/partner/cars',
      '/partner/trips',
      '/partner/trips/TRP-2847A',
      '/partner/earnings',
      '/partner/performance',
      '/partner/incentives',
      '/partner/alerts',
      '/partner/messages',
      '/partner/documents',
      '/partner/settings',
    ];

    final Map<String, Size> viewports = <String, Size>{
      'phone': const Size(390, 844),
      'tablet': const Size(768, 900),
      'desktop': const Size(1440, 900),
    };

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final MapEntry<String, Size> viewport in viewports.entries) {
      tester.view.physicalSize = viewport.value;
      tester.view.devicePixelRatio = 1;
      appRouter.go('/partner/dashboard');
      await tester.pumpWidget(const ProviderScope(child: YaApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (final String route in routes) {
        appRouter.go(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final Object? exception = tester.takeException();
        if (exception != null) {
          final String details = exception is FlutterError
              ? <String>[
                  exception.toStringDeep(),
                  for (final DiagnosticsNode node in exception.diagnostics)
                    node.toStringDeep(),
                ].join('\n')
              : exception.toString();
          fail(
            'Route failed at ${viewport.key} ${viewport.value}: $route\n'
            '$details',
          );
        }
      }
    }
  });
}
