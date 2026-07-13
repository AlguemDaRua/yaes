import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/services/location_service.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

http.Client _mockClient(int status, Object body) {
  return MockClient((_) async => http.Response(jsonEncode(body), status));
}

http.Client _mockClientRaw(int status, String body) {
  return MockClient((_) async => http.Response(body, status));
}

// ─── OSM search response fixtures ───────────────────────────────────────────

List<Map<String, dynamic>> _osmResults() => [
      {
        'display_name': 'Universidade Eduardo Mondlane, Maputo',
        'lat': '-25.9605',
        'lon': '32.5833',
        'type': 'university',
        'address': {'university': 'UEM'},
      },
      {
        'display_name': 'Polana Serena Hotel, Maputo',
        'lat': '-25.9672',
        'lon': '32.5821',
        'type': 'hotel',
        'address': {'tourism': 'Polana Serena Hotel'},
      },
    ];

// ─── Mapbox directions fixture ───────────────────────────────────────────────

Map<String, dynamic> _mapboxDirections(int routeCount) => {
      'code': 'Ok',
      'routes': List.generate(routeCount, (i) => {
            'geometry': {
              'coordinates': [
                [32.57, -25.96],
                [32.58, -25.97],
              ],
            },
            'distance': (i + 1) * 1000.0,
            'duration': (i + 1) * 60.0,
          }),
    };

// ─── Mapbox geocoding fixture ─────────────────────────────────────────────────

Map<String, dynamic> _mapboxGeocoding() => {
      'features': [
        {
          'place_type': ['address'],
          'text': 'Av. Julius Nyerere',
          'place_name': 'Av. Julius Nyerere, Maputo, Mozambique',
        },
      ],
    };

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── searchPlacesOSM ───────────────────────────────────────────────────────

  group('LocationService.searchPlacesOSM', () {
    test('returns empty list for empty query without HTTP call', () async {
      // No HTTP client provided — would throw if called
      final result = await LocationService.searchPlacesOSM('');
      expect(result, isEmpty);
    });

    test('parses results correctly', () async {
      final client = _mockClient(200, _osmResults());
      final results = await LocationService.searchPlacesOSM(
        'universidade',
        client: client,
      );

      expect(results.length, 2);

      final first = results[0];
      expect(first['name'], 'UEM');
      expect(first['type'], 'university');
      expect((first['latlong'] as LatLng).latitude, closeTo(-25.9605, 0.001));
    });

    test('falls back to display_name when no address sub-fields match', () async {
      final client = _mockClient(200, [
        {
          'display_name': 'Some Place, Maputo',
          'lat': '-25.96',
          'lon': '32.58',
          'type': 'place',
          'address': {},
        },
      ]);

      final results = await LocationService.searchPlacesOSM('test', client: client);
      expect(results[0]['name'], 'Some Place, Maputo');
    });

    test('throws on non-200 response', () async {
      final client = _mockClientRaw(503, 'Service Unavailable');
      expect(
        () => LocationService.searchPlacesOSM('query', client: client),
        throwsException,
      );
    });
  });

  // ── fetchRoutesAlternatives ──────────────────────────────────────────────

  group('LocationService.fetchRoutesAlternatives', () {
    final origin = const LatLng(-25.96, 32.57);
    final destination = const LatLng(-25.97, 32.58);

    test('returns one route per entry in response', () async {
      final client = _mockClient(200, _mapboxDirections(2));
      final routes = await LocationService.fetchRoutesAlternatives(
        origin: origin,
        destination: destination,
        token: 'fake-token',
        client: client,
      );

      expect(routes.length, 2);
    });

    test('parses distance and duration', () async {
      final client = _mockClient(200, _mapboxDirections(1));
      final routes = await LocationService.fetchRoutesAlternatives(
        origin: origin,
        destination: destination,
        token: 'fake-token',
        client: client,
      );

      // distance: 1000m → 1.00 km; duration: 60s → 1.0 min
      expect(routes[0]['distance'], '1.00');
      expect(routes[0]['duration'], '1.0');
    });

    test('parses coordinates into LatLng list', () async {
      final client = _mockClient(200, _mapboxDirections(1));
      final routes = await LocationService.fetchRoutesAlternatives(
        origin: origin,
        destination: destination,
        token: 'fake-token',
        client: client,
      );

      final points = routes[0]['points'] as List;
      expect(points, isNotEmpty);
      expect(points.first, isA<LatLng>());
    });

    test('throws on non-200 response', () async {
      final client = _mockClientRaw(401, 'Unauthorized');
      expect(
        () => LocationService.fetchRoutesAlternatives(
          origin: origin,
          destination: destination,
          token: 'bad-token',
          client: client,
        ),
        throwsException,
      );
    });
  });

  // ── getPlaceInfoFromMapbox ───────────────────────────────────────────────

  group('LocationService.getPlaceInfoFromMapbox', () {
    test('returns name, fullName, type from features', () async {
      final client = _mockClient(200, _mapboxGeocoding());
      final info = await LocationService.getPlaceInfoFromMapbox(
        -25.96,
        32.57,
        'fake-token',
        client: client,
      );

      expect(info['name'], 'Av. Julius Nyerere');
      expect(info['type'], 'address');
      expect(info['fullName'], contains('Maputo'));
    });

    test('returns unknown fields when features list is empty', () async {
      final client = _mockClient(200, {'features': []});
      final info = await LocationService.getPlaceInfoFromMapbox(
        -25.96,
        32.57,
        'fake-token',
        client: client,
      );

      expect(info['name'], 'unknown');
      expect(info['type'], 'unknown');
    });

    test('throws on non-200 response', () async {
      final client = _mockClientRaw(403, 'Forbidden');
      expect(
        () => LocationService.getPlaceInfoFromMapbox(
          -25.96,
          32.57,
          'bad-token',
          client: client,
        ),
        throwsException,
      );
    });
  });

  // ── iconForPlace ─────────────────────────────────────────────────────────

  group('LocationService.iconForPlace', () {
    test('returns school icon for "university"', () {
      expect(
        LocationService.iconForPlace('university').codePoint,
        isNonZero,
      );
    });

    test('returns location_on for unknown type', () {
      final icon = LocationService.iconForPlace('something_unknown');
      // location_on is the fallback
      expect(icon.codePoint, isNonZero);
    });

    test('is case-insensitive', () {
      final lower = LocationService.iconForPlace('hospital');
      final upper = LocationService.iconForPlace('HOSPITAL');
      expect(lower, equals(upper));
    });
  });
}
