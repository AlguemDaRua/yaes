import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ya_painel/shared/widgets/forms/ya_button.dart';
import 'package:ya_painel/theme/ya_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: YaTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('YaButton renders label and icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        YaButton.primary(
          label: 'Guardar',
          icon: LucideIcons.save,
          onPressed: () {},
        ),
      ),
    );

    expect(find.text('Guardar'), findsOneWidget);
    expect(find.byIcon(LucideIcons.save), findsOneWidget);
  });

  testWidgets('YaButton calls onPressed when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        YaButton.secondary(
          label: 'Abrir',
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('YaButton ignores taps while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        YaButton.primary(
          label: 'A processar',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('A processar'));
    await tester.pump();

    expect(find.text('A processar'), findsOneWidget);
    expect(taps, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('YaButton ignores taps when disabled', (tester) async {
    await tester.pumpWidget(
      _wrap(const YaButton.ghost(label: 'Indisponivel')),
    );

    await tester.tap(find.text('Indisponivel'));
    await tester.pump();

    expect(find.text('Indisponivel'), findsOneWidget);
  });

  testWidgets('YaButton destructive variant renders label', (tester) async {
    await tester.pumpWidget(
      _wrap(YaButton.destructive(label: 'Eliminar', onPressed: () {})),
    );

    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('YaButton link variant handles taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(YaButton.link(label: 'Ver mais', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Ver mais'));
    await tester.pump();

    expect(taps, 1);
  });
}
