import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final NotifierProvider<LocaleController, Locale> localeProv =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

Locale _initialLocale = const Locale('pt');

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => _initialLocale;

  void setLocale(Locale locale) {
    state = locale;
  }
}

class LocaleNotifier {
  const LocaleNotifier._();

  static const String _key = 'locale';

  static void setInitial(Locale locale) {
    _initialLocale = locale;
  }

  static Future<Locale> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String code = prefs.getString(_key) ?? 'pt';
    return Locale(code);
  }

  static Future<void> save(Locale locale, WidgetRef ref) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    ref.read(localeProv.notifier).setLocale(locale);
  }
}
