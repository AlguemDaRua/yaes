class MapConfig {
  static const String token =
      'pk.eyJ1IjoiYWRpbHNvbm11aWFuZ2EiLCJhIjoiY21nOGNnams3MDY5YzJsczc5cG4xZjFpdCJ9.oQK2hk0BJMYnaFWRjEmmXw';

  static String get streetsTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';

  static String get darkTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$token';

  static String get satelliteTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
}
