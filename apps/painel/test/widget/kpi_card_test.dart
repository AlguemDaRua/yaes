import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ya_painel/shared/widgets/feedback/skeleton.dart';
import 'package:ya_painel/shared/widgets/kpi/kpi_card.dart';
import 'package:ya_painel/theme/ya_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: YaTheme.light(),
    home: Scaffold(
      body: SizedBox(width: 360, child: child),
    ),
  );
}

void main() {
  testWidgets('KpiCard renders label, value, suffix, icon and trend',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const KpiCard(
          label: 'Receita mensal',
          value: '1 234',
          valueSuffix: 'MTn',
          icon: LucideIcons.wallet,
          trend: KpiTrend(
            value: '+12%',
            direction: TrendDirection.up,
            semantic: TrendSemantic.positive,
            label: 'vs Abril',
          ),
        ),
      ),
    );

    expect(find.text('RECEITA MENSAL'), findsOneWidget);
    expect(find.text('1 234'), findsOneWidget);
    expect(find.text('MTn'), findsOneWidget);
    expect(find.text('+12%'), findsOneWidget);
    expect(find.text('vs Abril'), findsOneWidget);
    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
  });

  testWidgets('KpiCard renders skeleton while loading', (tester) async {
    await tester.pumpWidget(
      _wrap(const KpiCard(label: 'Receita', value: '0', loading: true)),
    );

    expect(find.byType(Skeleton), findsNWidgets(3));
  });

  testWidgets('KpiCard renders empty state value', (tester) async {
    await tester.pumpWidget(
      _wrap(const KpiCard(label: 'Sem dados', value: '0', empty: true)),
    );

    expect(find.text('SEM DADOS'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('KpiCard renders a negative trend', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const KpiCard(
          label: 'Cancelamentos',
          value: '3',
          trend: KpiTrend(
            value: '-2%',
            direction: TrendDirection.down,
            semantic: TrendSemantic.negative,
            label: 'vs ontem',
          ),
        ),
      ),
    );

    expect(find.text('-2%'), findsOneWidget);
    expect(find.text('vs ontem'), findsOneWidget);
  });

  testWidgets('KpiCard row lays out multiple cards', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const KpiRow(
          children: [
            KpiCard(label: 'A', value: '1'),
            KpiCard(label: 'B', value: '2'),
          ],
        ),
      ),
    );

    expect(find.byType(KpiCard), findsNWidgets(2));
  });

  testWidgets('KpiCard calls onTap when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        KpiCard(
          label: 'Corridas',
          value: '42',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('CORRIDAS'));
    await tester.pump();

    expect(taps, 1);
  });
}
