import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:provider/provider.dart';

class LocationService {
  static Future<List<Map<String, dynamic>>> fetchRoutesStatic({
    required LatLng origin,
    required LatLng destination,
    required String token,
    required List<Map<String, dynamic>> stops,
  }) async {
    // 1. Build the coordinates string
    final buffer = StringBuffer();

    // Origin
    buffer.write('${origin.longitude},${origin.latitude}');

    // Intermediate stops
    for (final stop in stops) {
      final latlng = stop['latlong'] as LatLng;
      buffer.write(';${latlng.longitude},${latlng.latitude}');
    }

    // Destination
    buffer.write(';${destination.longitude},${destination.latitude}');

    // 2. Build the Optimization API URL
    final url =
        'https://api.mapbox.com/optimized-trips/v1/mapbox/driving/${buffer.toString()}'
        '?geometries=geojson&overview=full&source=first&destination=last&roundtrip=false&access_token=$token';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final trip = data['trips'][0];
      final coords = trip['geometry']['coordinates'] as List;

      return [
        {
          'points': coords.map((c) => LatLng(c[1], c[0])).toList(),
          'distance': (trip['distance'] / 1000).toStringAsFixed(2), // km
          'duration': (trip['duration'] / 60).toStringAsFixed(1), // min
          'waypoints': data['waypoints'], // optimised order
        },
      ];
    } else {
      throw Exception('Erro ao buscar rota otimizada: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRoutesAlternatives({
    required LatLng origin,
    required LatLng destination,
    required String token,
    List<Map<String, dynamic>> stops = const [],
    http.Client? client,
  }) async {
    // 1. Build the coordinates string
    final buffer = StringBuffer();

    // Origin
    buffer.write('${origin.longitude},${origin.latitude}');

    // Intermediate stops
    for (final stop in stops) {
      LatLng latlng = stop["latlong"];
      buffer.write(';${latlng.longitude},${latlng.latitude}');
    }

    // Destination
    buffer.write(';${destination.longitude},${destination.latitude}');

    // Build the full URL
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${buffer.toString()}'
        '?alternatives=true&geometries=geojson&overview=full&access_token=$token';

    final httpClient = client ?? http.Client();
    final response = await httpClient.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final routes = data['routes'] as List;

      // Each route has: points, distance, and duration
      return routes.map((route) {
        final coords = route['geometry']['coordinates'] as List;
        return {
          'points': coords.map((c) => LatLng(c[1], c[0])).toList(),
          'distance': (route['distance'] / 1000).toStringAsFixed(2), // km
          'duration': (route['duration'] / 60).toStringAsFixed(1), // min
        };
      }).toList();
    } else {
      throw Exception('Erro ao buscar rotas');
    }
  }

  static Future<List<Map<String, dynamic>>> searchPlacesOSM(
    String query, {
    http.Client? client,
  }) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=10&countrycodes=mz',
    );

    final httpClient = client ?? http.Client();
    final response = await httpClient.get(
      url,
      headers: {
        'User-Agent': 'ya-app/1.0',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;

      return data.map((place) {
        final address = place["address"] ?? {};
        final osmType = place["type"];
        final finalType = '$osmType';

        return {
          "name":
              address["university"] ??
              address["amenity"] ?? // POI name (restaurant, school, hospital, etc.)
              address["shop"] ?? // shop name
              address["tourism"] ?? // tourist attraction
              address["leisure"] ?? // park, stadium, etc.
              address["office"] ?? // offices
              address["man_made"] ?? // built structures
              address["building"] ?? // specific building
              place["display_name"], // fallback (full address)          "fullName": place["display_name"],
          "fullName": place["display_name"],
          "type": finalType,
          "latlong": LatLng(
            double.parse(place["lat"]),
            double.parse(place["lon"]),
          ),
        };
      }).toList();
    } else {
      throw Exception("Erro ao buscar locais: ${response.statusCode}");
    }
  }

  static Future<void> onSearchChanged({
    required String query,
    required BuildContext context,
  }) async {
    final appState = Provider.of<PassengerState>(context, listen: false);
    try {
      final results = await LocationService.searchPlacesOSM(query);

      appState.address = results;
    } catch (e) {
      debugPrint('Location search failed: $e');
      appState.address = [];
    }
  }

  // reverse geocode to get the nearest place name
  static Future<Map<String, String>> getPlaceInfoFromMapbox(
    double lat,
    double lng,
    String token, {
    http.Client? client,
  }) async {
    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/"
        "$lng,$lat.json"
        "?access_token=$token"
        "&types=address,place,neighborhood"
        "&limit=1";

    final httpClient = client ?? http.Client();
    final response = await httpClient.get(
      Uri.parse(url),
      headers: {"User-Agent": "ya-app/1.0"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data['features'] as List;

      if (features.isNotEmpty) {
        final f = features.first;
        return {
          "type": (f['place_type'] as List).first,
          "name": f['text'],
          "fullName": f['place_name'],
        };
      }
    } else {
      throw Exception("Erro Mapbox ${response.statusCode}");
    }

    return {"type": "unknown", "name": "unknown", "fullName": "unknown"};
  }

  static Future<Map<String, String>> getPlaceInfoFromNominatim(
    double lat,
    double lng, {
    http.Client? client,
  }) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1";

    final httpClient = client ?? http.Client();
    final response = await httpClient.get(
      Uri.parse(url),
      headers: {
        "User-Agent": "limousineexecutive-app", // Nominatim requires a User-Agent
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        "type": data['type'] ?? 'Unknown',
        "name": data['name'] ?? data['display_name'],
        "fullName": data['display_name'] ?? "unknown",
      };
    } else {
      throw Exception("Erro ao obter local: ${response.statusCode}");
    }
  }

  // Icon map for each location type
  static IconData iconForPlace(String type) {
    switch (type.toLowerCase()) {
      case "school":
      case "university":
        return Icons.school;
      case "hospital":
      case "clinic":
      case "doctors":
        return Icons.local_hospital;
      case "restaurant":
      case "fast_food":
        return Icons.restaurant;
      case "hotel":
      case "guest_house":
        return Icons.hotel;
      case "bank":
      case "atm":
        return Icons.account_balance;
      case "cafe":
      case "bar":
      case "pub":
        return Icons.local_cafe;
      case "supermarket":
      case "bakery":
      case "clothes":
      case "shop":
      case "kiosk":
        return Icons.shopping_bag;
      case "pharmacy":
        return Icons.local_pharmacy;
      case "bus_stop":
      case "railway_station":
      case "station":
        return Icons.directions_bus;
      case "parking":
        return Icons.local_parking;
      case "museum":
      case "attraction":
        return Icons.museum;
      case "post_office":
        return Icons.local_post_office;
      case "police":
        return Icons.local_police;
      case "library":
        return Icons.local_library;
      case "city":
      case "town":
      case "suburb":
      case "village":
        return Icons.location_city;
      case "office":
      case "building":
        return Icons.business;
      case "park":
      case "stadium":
      case "pitch":
        return Icons.park;
      case 'fuel':
        return Icons.local_gas_station;
      case 'primary':
      case 'secondary':
      case 'residential':
      case 'highway':
        return Icons.add_road;
      case "aerodrome":
      case "aeroway":
      case "airport":
        return Icons.local_airport;
      default:
        return Icons.location_on; // fallback
    }
  }
}
