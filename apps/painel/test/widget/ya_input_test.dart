import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ya_painel/shared/widgets/forms/ya_input.dart';
import 'package:ya_painel/theme/ya_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: YaTheme.light(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('YaInput renders label, hint, placeholder and icon',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const YaInput(
          label: 'Email',
          placeholder: 'admin@ya.co.mz',
          hint: 'Usa o email da conta',
          icon: LucideIcons.mail,
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Usa o email da conta'), findsOneWidget);
    expect(find.byIcon(LucideIcons.mail), findsOneWidget);

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.hintText, 'admin@ya.co.mz');
  });

  testWidgets('YaInput updates controller and calls onChanged', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var lastValue = '';

    await tester.pumpWidget(
      _wrap(
        YaInput(
          controller: controller,
          label: 'Nome',
          onChanged: (value) => lastValue = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Maputo Executive');
    await tester.pump();

    expect(controller.text, 'Maputo Executive');
    expect(lastValue, 'Maputo Executive');
  });

  testWidgets('YaInput calls onSubmitted', (tester) async {
    var submitted = '';
    await tester.pumpWidget(
      _wrap(
        YaInput(
          label: 'Pesquisar',
          onSubmitted: (value) => submitted = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'drivers');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, 'drivers');
  });

  testWidgets('YaInput shows error instead of hint', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const YaInput(
          label: 'NUIT',
          hint: '9 digitos',
          errorText: 'NUIT invalido',
        ),
      ),
    );

    expect(find.text('NUIT invalido'), findsOneWidget);
    expect(find.text('9 digitos'), findsNothing);
  });

  testWidgets('YaInput can be disabled', (tester) async {
    await tester.pumpWidget(
      _wrap(const YaInput(label: 'Telefone', enabled: false)),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);
  });
}
