import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ya_painel/main.dart';
import 'package:ya_painel/router/app_router.dart';

void main() {
  testWidgets('inline dialogs close without popping the app route', (
    tester,
  ) async {
    await initializeDateFormatting('pt_PT');
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();

    appRouter.go('/admin/partners/ptr-maputo-exec');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Editar comissão'));
    await tester.pump();
    expect(find.text('Alterar comissão'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Alterar comissão'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Suspender'));
    await tester.pump();
    expect(find.text('Suspender'), findsWidgets);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Suspender Maputo Executive?'), findsNothing);
    expect(tester.takeException(), isNull);

    appRouter.go('/admin/trips/TRP-2847A');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Emitir reembolso'));
    await tester.pump();
    expect(find.text('Emitir reembolso · TRP-2847A'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Emitir reembolso · TRP-2847A'), findsNothing);
    expect(tester.takeException(), isNull);

    appRouter.go('/admin/commissions');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Editar').first);
    await tester.pump();
    expect(find.text('Comissão de Maputo Executive'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Comissão de Maputo Executive'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
