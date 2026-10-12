import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/saved_place.dart';

Map<String, dynamic> _entry(String name, {Map<String, dynamic>? extra}) => {
  'name': name,
  'fullName': '$name, Nampula',
  'lat': -15.1165,
  'lng': 39.2666,
  ...?extra,
};

void main() {
  group('SavedPlace.parseAll', () {
    test('returns an empty list for null, non-map and empty values', () {
      expect(SavedPlace.parseAll(null), isEmpty);
      expect(SavedPlace.parseAll('texto'), isEmpty);
      expect(SavedPlace.parseAll(<String, dynamic>{}), isEmpty);
    });

    test('puts Casa and Trabalho first, then the others oldest to newest', () {
      final places = SavedPlace.parseAll({
        '1700000002000': _entry('Mercado'),
        'work': _entry('Escritório'),
        '1700000001000': _entry('Escola'),
        'home': _entry('Rua da Casa'),
      });

      expect(places.map((p) => p.id), [
        'home',
        'work',
        '1700000001000',
        '1700000002000',
      ]);
      expect(places.map((p) => p.kind), [
        SavedPlaceKind.home,
        SavedPlaceKind.work,
        SavedPlaceKind.other,
        SavedPlaceKind.other,
      ]);
    });

    test('reads the maps that Firebase returns (Object? keys and values)', () {
      final raw = <Object?, Object?>{
        'home': <Object?, Object?>{
          'name': 'Rua da Casa',
          'fullName': 'Rua da Casa, Nampula',
          'lat': -15.1165,
          'lng': 39.2666,
        },
      };

      final places = SavedPlace.parseAll(raw);

      expect(places, hasLength(1));
      expect(places.single.name, 'Rua da Casa');
      expect(places.single.fullName, 'Rua da Casa, Nampula');
      expect(places.single.location, const LatLng(-15.1165, 39.2666));
    });

    test('accepts whole numbers and numeric strings as coordinates', () {
      final places = SavedPlace.parseAll({
        'home': {'name': 'A', 'lat': -15, 'lng': 39},
        'work': {'name': 'B', 'lat': '-15.5', 'lng': '39.5'},
      });

      expect(places[0].location, const LatLng(-15, 39));
      expect(places[1].location, const LatLng(-15.5, 39.5));
    });

    test('ignores invalid entries instead of failing', () {
      final places = SavedPlace.parseAll({
        'home': _entry('Válida'),
        'work': 'não é um mapa',
        '1': {'name': 'Sem coordenadas'},
        '2': {'name': 'Latitude fora do intervalo', 'lat': 95, 'lng': 10},
        '3': {'name': 'Longitude fora do intervalo', 'lat': 10, 'lng': 200},
        '4': {'name': 'Coordenada inválida', 'lat': double.nan, 'lng': 10},
        '5': {'lat': -15.1, 'lng': 39.2},
        '6': {'name': '   ', 'fullName': '', 'lat': -15.1, 'lng': 39.2},
      });

      expect(places.map((p) => p.id), ['home']);
    });

    test('falls back to fullName when name is missing', () {
      final places = SavedPlace.parseAll({
        '1': {'fullName': 'Av. Eduardo Mondlane', 'lat': -15.1, 'lng': 39.2},
      });

      expect(places.single.name, 'Av. Eduardo Mondlane');
    });

    test('returns a list that cannot be modified', () {
      final places = SavedPlace.parseAll({'home': _entry('A')});

      expect(
        () => places.add(places.first),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('SavedPlace.title', () {
    test('uses Casa and Trabalho for the fixed places', () {
      final places = SavedPlace.parseAll({
        'home': _entry('Rua A'),
        'work': _entry('Rua B'),
      });

      expect(places.map((p) => p.title), ['Casa', 'Trabalho']);
    });

    test('uses the geocoded name for old places without a label', () {
      final places = SavedPlace.parseAll({'1': _entry('Mercado Central')});

      expect(places.single.title, 'Mercado Central');
    });

    test('prefers the label chosen by the user, trimmed', () {
      final places = SavedPlace.parseAll({
        '1': _entry('Igreja Católica de Nacuto', extra: {'label': '  Igreja '}),
      });

      expect(places.single.title, 'Igreja');
      expect(places.single.name, 'Igreja Católica de Nacuto');
    });

    test('ignores an empty label', () {
      final places = SavedPlace.parseAll({
        '1': _entry('Mercado', extra: {'label': '   '}),
      });

      expect(places.single.label, isNull);
      expect(places.single.title, 'Mercado');
    });
  });

  group('SavedPlace equality', () {
    test('two places with the same data are equal', () {
      const a = SavedPlace(
        id: 'home',
        kind: SavedPlaceKind.home,
        name: 'Rua A',
        fullName: 'Rua A, Nampula',
        location: LatLng(-15.1, 39.2),
      );
      const b = SavedPlace(
        id: 'home',
        kind: SavedPlaceKind.home,
        name: 'Rua A',
        fullName: 'Rua A, Nampula',
        location: LatLng(-15.1, 39.2),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different label makes them different', () {
      const a = SavedPlace(
        id: '1',
        kind: SavedPlaceKind.other,
        name: 'Rua A',
        fullName: '',
        location: LatLng(-15.1, 39.2),
      );
      const b = SavedPlace(
        id: '1',
        kind: SavedPlaceKind.other,
        name: 'Rua A',
        fullName: '',
        location: LatLng(-15.1, 39.2),
        label: 'Igreja',
      );

      expect(a == b, isFalse);
    });
  });
}
