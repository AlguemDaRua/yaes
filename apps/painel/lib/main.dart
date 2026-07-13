import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/locale_provider.dart';
import 'app/theme_mode_provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/config.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'router/app_router.dart';
import 'shared/widgets/feedback/app_error_widget.dart';
import 'theme/ya_theme.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ErrorWidget.builder = (details) => AppErrorWidget(details: details);
      await initializeDateFormatting('pt_PT');
      final Locale savedLocale = await LocaleNotifier.load();
      LocaleNotifier.setInitial(savedLocale);
      if (kUseFirebase) {
        await _initializeFirebase();
        await authNotifier.useFirebaseAuth();
      }
      runApp(const ProviderScope(child: YaApp()));
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error\n$stackTrace');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'YA bootstrap',
        ),
      );
    },
  );
}

Future<void> _initializeFirebase() async {
  final FirebaseOptions options = DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(
    // Under emulators, point at the `ya-app-z-default-rtdb` namespace — the
    // default RTDB instance where triggers, rules and the functions'
    // admin.database() attach (same as production). The bare `ya-app-z`
    // namespace is a separate instance that triggers never observe, so
    // callable-function writes and the invite trigger would silently miss.
    options: kUseEmulators
        ? options.copyWith(
            databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
          )
        : options,
  );

  if (!kUseEmulators) return;

  FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}

class YaApp extends ConsumerWidget {
  const YaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProv);
    return MaterialApp.router(
      onGenerateTitle: (context) => S.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,
      theme: YaTheme.light(),
      darkTheme: YaTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
