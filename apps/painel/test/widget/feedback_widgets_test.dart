import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ya_painel/core/constants/status_mapping.dart';
import 'package:ya_painel/shared/widgets/feedback/empty_state.dart';
import 'package:ya_painel/shared/widgets/feedback/status_badge.dart';
import 'package:ya_painel/theme/ya_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: YaTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('EmptyState renders title, description and icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EmptyState(
          icon: LucideIcons.inbox,
          title: 'Sem resultados',
          description: 'Ajusta os filtros e tenta novamente.',
        ),
      ),
    );

    expect(find.text('Sem resultados'), findsOneWidget);
    expect(find.text('Ajusta os filtros e tenta novamente.'), findsOneWidget);
    expect(find.byIcon(LucideIcons.inbox), findsOneWidget);
  });

  testWidgets('EmptyState renders CTA and handles tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          icon: LucideIcons.circleAlert,
          title: 'Nada aqui',
          description: 'Ainda nao ha itens.',
          ctaLabel: 'Criar',
          onCta: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Criar'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('StatusBadge renders direct variant label and dot',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatusBadge(
          variant: StatusVariant.success,
          label: 'Activo',
        ),
      ),
    );

    expect(find.text('Activo'), findsOneWidget);
    expect(find.byType(StatusBadge), findsOneWidget);
  });

  testWidgets('StatusBadge can render from canonical mapping', (tester) async {
    await tester.pumpWidget(
      _wrap(StatusBadge.fromMapping(YaStatus.transactionPending)),
    );

    expect(find.text('Pendente'), findsOneWidget);
  });

  testWidgets('StatusBadge can render with an icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatusBadge(
          variant: StatusVariant.info,
          label: 'Info',
          icon: LucideIcons.info,
        ),
      ),
    );

    expect(find.text('Info'), findsOneWidget);
    expect(find.byIcon(LucideIcons.info), findsOneWidget);
  });
}
