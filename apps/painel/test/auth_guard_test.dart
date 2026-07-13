import 'dart:ui';

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

  tearDown(() {
    authNotifier.setRoleForTest(UserRole.admin);
  });

  testWidgets('unauthenticated user is redirected to login', (tester) async {
    await authNotifier.signOut();
    _setDesktopViewport(tester);

    appRouter.go('/admin/dashboard');
    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(appRouter.routeInformationProvider.value.uri.toString(), '/login');
    expect(tester.takeException(), isNull);
  });

  testWidgets('partner is redirected away from admin routes', (tester) async {
    authNotifier.setRoleForTest(UserRole.partner);
    _setDesktopViewport(tester);

    appRouter.go('/admin/dashboard');
    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      appRouter.routeInformationProvider.value.uri.toString(),
      '/partner/dashboard',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('support is redirected away from partner routes', (tester) async {
    authNotifier.setRoleForTest(UserRole.support);
    _setDesktopViewport(tester);

    appRouter.go('/partner/dashboard');
    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(appRouter.routeInformationProvider.value.uri.toString(), '/support');
    expect(tester.takeException(), isNull);
  });
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
