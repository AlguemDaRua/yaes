import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ya_painel/main.dart';

void main() {
  testWidgets('renders the admin dashboard smoke page', (tester) async {
    await initializeDateFormatting('pt_PT');
    await tester.pumpWidget(const ProviderScope(child: YaApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('PARTNERS ACTIVOS'), findsOneWidget);
    expect(find.text('Receita mensal'), findsOneWidget);
    expect(find.text('Corridas recentes'), findsOneWidget);
  });
}
