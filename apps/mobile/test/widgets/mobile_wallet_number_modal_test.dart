import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:limousineexecutive/passenger/components/bottomsheet/mobile_wallet_number_modal.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final originalRuntimeFetching = GoogleFonts.config.allowRuntimeFetching;

  setUpAll(() async {
    // These interaction tests use a bundled font fixture, so opening the sheet
    // never depends on Google Fonts or the machine's network/font cache.
    final fontBytes = await rootBundle.load('assets/fonts/Gagalin.ttf');
    final manifestBytes = await rootBundle.load('AssetManifest.bin');
    const codec = StandardMessageCodec();
    final manifest = Map<Object?, Object?>.from(
      codec.decodeMessage(manifestBytes)! as Map,
    );
    final assets = <String, ByteData>{};
    for (final method in MobileWalletMethod.values) {
      assets[method.imageAsset] = await rootBundle.load(method.imageAsset);
    }
    for (final variant in [
      'Thin',
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Black',
    ]) {
      final asset = 'assets/fonts/Poppins-$variant.ttf';
      manifest[asset] = [
        <String, Object?>{'asset': asset},
      ];
      assets[asset] = fontBytes;
    }
    final testManifest = codec.encodeMessage(manifest);
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      message,
    ) async {
      final asset = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      if (asset == 'AssetManifest.bin') return testManifest;
      if (assets.containsKey(asset)) return assets[asset];
      return binding.defaultBinaryMessenger.delegate.send(
        'flutter/assets',
        message,
      );
    });
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() {
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
    GoogleFonts.config.allowRuntimeFetching = originalRuntimeFetching;
  });

  for (final method in MobileWalletMethod.values) {
    testWidgets('${method.label} identifies the wallet and saves its number', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final savedNumbers = <String>[];
        final result = await _openModal(
          tester,
          method: method,
          onSave: (number) async => savedNumbers.add(number),
        );

        expect(find.textContaining(method.label), findsWidgets);
        expect(find.text('+258'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Número de telemóvel ${method.label}')),
          findsOneWidget,
        );
        expect(find.byTooltip('Fechar'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);

        final images = tester.widgetList<Image>(find.byType(Image));
        expect(
          images.any(
            (image) =>
                image.image is AssetImage &&
                (image.image as AssetImage).assetName == method.imageAsset,
          ),
          isTrue,
        );

        final localNumber = method == MobileWalletMethod.mpesa
            ? '84 123 4567'
            : '86 123 4567';
        await tester.enterText(find.byType(TextFormField), localNumber);
        await _save(tester);
        await tester.pumpAndSettle();

        expect(savedNumbers, ['+258${localNumber.replaceAll(' ', '')}']);
        expect(result.completed, isTrue);
        expect(result.value, isTrue);
        expect(find.byType(TextFormField), findsNothing);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final number in ['+258 84 123 4567', '00258 84 123 4567']) {
    testWidgets('normalizes a pasted international number: $number', (
      tester,
    ) async {
      String? savedNumber;
      await _openModal(tester, onSave: (number) async => savedNumber = number);

      await tester.enterText(find.byType(TextFormField), number);
      await _save(tester);
      await tester.pumpAndSettle();

      expect(savedNumber, '+258841234567');
      expect(find.byType(TextFormField), findsNothing);
    });
  }

  for (final number in ['', '84123456', '8412345678']) {
    testWidgets('rejects a number without exactly nine local digits: $number', (
      tester,
    ) async {
      var saveCalls = 0;
      final result = await _openModal(tester, onSave: (_) async => saveCalls++);

      await tester.enterText(find.byType(TextFormField), number);
      await _save(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('9 dígitos'), findsOneWidget);
      expect(saveCalls, 0);
      expect(result.completed, isFalse);
      expect(find.byType(TextFormField), findsOneWidget);
    });
  }

  testWidgets('formats an existing number and cancels without saving', (
    tester,
  ) async {
    var saveCalls = 0;
    final result = await _openModal(
      tester,
      initialNumber: '+258841234567',
      onSave: (_) async => saveCalls++,
    );

    expect(_numberText(tester), '84 123 4567');

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(saveCalls, 0);
    expect(result.completed, isTrue);
    expect(result.value, isNot(true));
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets(
    'keeps the sheet open and blocks duplicate submissions while saving',
    (tester) async {
      final pendingSave = Completer<void>();
      var saveCalls = 0;
      final result = await _openModal(
        tester,
        onSave: (_) {
          saveCalls++;
          return pendingSave.future;
        },
      );

      await tester.enterText(find.byType(TextFormField), '84 123 4567');
      await _save(tester);
      await tester.pump();

      expect(saveCalls, 1);
      expect(result.completed, isFalse);
      expect(find.text('A guardar…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'A guardar…'),
            )
            .onPressed,
        isNull,
      );
      final closeButton = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Fechar',
      );
      expect(tester.widget<IconButton>(closeButton).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'A guardar…'));
      await tester.tap(closeButton);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.tapAt(const Offset(8, 8));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));

      expect(saveCalls, 1);
      expect(result.completed, isFalse);
      expect(find.byType(TextFormField), findsOneWidget);

      pendingSave.complete();
      await tester.pumpAndSettle();

      expect(result.completed, isTrue);
      expect(result.value, isTrue);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('preserves the number after a save error and allows a retry', (
    tester,
  ) async {
    final savedNumbers = <String>[];
    var saveCalls = 0;
    final result = await _openModal(
      tester,
      method: MobileWalletMethod.emola,
      onSave: (number) async {
        saveCalls++;
        if (saveCalls == 1) {
          throw StateError('Connection unavailable');
        }
        savedNumbers.add(number);
      },
    );

    await tester.enterText(find.byType(TextFormField), '87 123 4567');
    await _save(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível guardar. Verifica a ligação e tenta novamente.',
      ),
      findsOneWidget,
    );
    expect(_numberText(tester), '87 123 4567');
    expect(result.completed, isFalse);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar número'),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);

    await _save(tester);
    await tester.pumpAndSettle();

    expect(saveCalls, 2);
    expect(savedNumbers, ['+258871234567']);
    expect(result.completed, isTrue);
    expect(result.value, isTrue);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('recovers from a stalled save and allows the user to cancel', (
    tester,
  ) async {
    final pendingSave = Completer<void>();
    final result = await _openModal(tester, onSave: (_) => pendingSave.future);

    await tester.enterText(find.byType(TextFormField), '84 123 4567');
    await _save(tester);
    await tester.pump();
    expect(find.text('A guardar…'), findsOneWidget);

    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível guardar. Verifica a ligação e tenta novamente.',
      ),
      findsOneWidget,
    );
    expect(_numberText(tester), '84 123 4567');
    expect(result.completed, isFalse);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guardar número'),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(result.completed, isTrue);
    expect(result.value, isNot(true));
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the form usable on a small screen with keyboard and larger text',
    (tester) async {
      String? savedNumber;
      await _openModal(
        tester,
        size: const Size(320, 640),
        textScale: 1.4,
        onSave: (number) async => savedNumber = number,
      );

      await tester.tap(find.byType(TextFormField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '84 123 4567');

      final saveButton = find.widgetWithText(FilledButton, 'Guardar número');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(saveButton.hitTestable(), findsOneWidget);
      expect(tester.getSize(saveButton).height, greaterThanOrEqualTo(48));

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedNumber, '+258841234567');
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<_ModalResult> _openModal(
  WidgetTester tester, {
  MobileWalletMethod method = MobileWalletMethod.mpesa,
  String? initialNumber,
  required Future<void> Function(String number) onSave,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  final result = _ModalResult();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          // The test SDK does not bundle InkSparkle's fragment shader.
          splashFactory: InkRipple.splashFactory,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE5A400)),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: const ValueKey('open-wallet-modal'),
                onPressed: () async {
                  result.value = await showMobileWalletNumberModal(
                    context,
                    method: method,
                    initialNumber: initialNumber,
                    onSave: onSave,
                  );
                  result.completed = true;
                },
                child: const Text('Adicionar carteira'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('open-wallet-modal')));
  await tester.pumpAndSettle();
  return result;
}

Future<void> _save(WidgetTester tester) async {
  final saveButton = find.widgetWithText(FilledButton, 'Guardar número');
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
}

String _numberText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

class _ModalResult {
  bool completed = false;
  bool? value;
}
