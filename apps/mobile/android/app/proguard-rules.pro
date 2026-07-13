# Mantém classes do Flutter
-keep class io.flutter.** { *; }

# Mantém classes da Play Core usadas pelo Flutter (se necessário)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Mantém classes do Mapbox (API, GeoJSON, Services)
-keep class com.mapbox.** { *; }
-keep class com.mapbox.api.** { *; }
-keep class com.mapbox.geojson.** { *; }
-keep class com.mapbox.services.** { *; }
-dontwarn com.mapbox.**

# Mantém classes de rede usadas pelo Mapbox
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Mantém classes usadas pelo pacote http do Dart/Flutter
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Mantém classes usadas para parsing JSON
-keep class org.json.** { *; }
-dontwarn org.json.**

# Evita warnings de anotações e Kotlin
-dontwarn javax.annotation.**
-dontwarn kotlin.**
-dontwarn sun.misc.Unsafe

# Mantém classes usadas pelo LatLng (latlong2)
-keep class org.osmdroid.util.GeoPoint { *; }
-keep class com.google.android.gms.maps.model.LatLng { *; }
-keep class com.mapbox.mapboxsdk.geometry.LatLng { *; }
-dontwarn org.osmdroid.**
-dontwarn com.google.android.gms.maps.**
-dontwarn com.mapbox.mapboxsdk.**
