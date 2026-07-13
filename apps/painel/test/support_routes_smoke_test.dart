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
  testWidgets('support routes render without Flutter errors', (tester) async {
    await initializeDateFormatting('pt_PT');
    authNotifier.setRoleForTest(UserRole.support);

    final List<String> routes = <String>[
      '/login',
      '/forgot-password',
      '/support',
      '/support/dashboard',
      '/support/queue',
      '/support/queue?ticket=TKT-2891',
      '/support/tickets',
      '/support/tickets/TKT-2891',
      '/support/chat',
      '/support/actions',
      '/support/disputes',
      '/support/performance',
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
      appRouter.go('/support');
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
