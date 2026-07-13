class AppConfig {
  static const String _envToken = String.fromEnvironment('MAPBOX_TOKEN');
  static const String _fallbackToken =
      'pk.eyJ1IjoiYWRpbHNvbm11aWFuZ2EiLCJhIjoiY21nOGNnams3MDY5YzJsczc5cG4xZjFpdCJ9.oQK2hk0BJMYnaFWRjEmmXw';

  static String get mapboxToken =>
      _envToken.isNotEmpty ? _envToken : _fallbackToken;
}
