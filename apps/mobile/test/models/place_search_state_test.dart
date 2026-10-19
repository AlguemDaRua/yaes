import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/place_search_state.dart';

Map<String, dynamic> _place(String name) => {
  'name': name,
  'fullName': '$name, Nampula, Moçambique',
  'type': 'place_of_worship',
  'latlong': const LatLng(-15.1165, 39.2666),
};

List<Object?> _names(PlaceSearchState state) =>
    state.places.map((place) => place['name']).toList();

void main() {
  late List<String> queries;
  late List<Completer<List<Map<String, dynamic>>>> pending;
  late PlaceSearchState state;

  // Pesquisa falsa: cada chamada fica pendente até o teste a responder.
  Future<List<Map<String, dynamic>>> fakeSearch(String query) {
    queries.add(query);
    final completer = Completer<List<Map<String, dynamic>>>();
    pending.add(completer);
    return completer.future;
  }

  setUp(() {
    queries = [];
    pending = [];
    state = PlaceSearchState(
      suggestions: [_place('Aeroporto')],
      search: fakeSearch,
    );
  });

  group('PlaceSearchState', () {
    test('shows the suggestions until a search is made', () {
      expect(_names(state), ['Aeroporto']);
      expect(state.noResults, isFalse);
      expect(state.failed, isFalse);
      expect(queries, isEmpty);
    });

    test('searches the trimmed text and shows what it finds', () async {
      final done = state.searchNow('  igreja  ');

      expect(queries, ['igreja']);
      pending.single.complete([_place('Igreja Católica de Nacuto')]);
      await done;

      expect(_names(state), ['Igreja Católica de Nacuto']);
      expect(state.noResults, isFalse);
      expect(state.failed, isFalse);
    });

    test('keeps the suggestions while the search is pending', () async {
      final done = state.searchNow('igreja');

      expect(_names(state), ['Aeroporto']);

      pending.single.complete([]);
      await done;
    });

    test('notifies listeners once per finished search', () async {
      var notifications = 0;
      state.addListener(() => notifications++);

      final done = state.searchNow('igreja');
      expect(notifications, 0);

      pending.single.complete([_place('Igreja Católica de Nacuto')]);
      await done;

      expect(notifications, 1);
    });

    test('tells when nothing was found', () async {
      final done = state.searchNow('xyzxyz');
      pending.single.complete([]);
      await done;

      expect(state.places, isEmpty);
      expect(state.noResults, isTrue);
      expect(state.failed, isFalse);
    });

    test('reports a failure and recovers on the next search', () async {
      final first = state.searchNow('igreja');
      pending[0].completeError(Exception('sem rede'));
      await first;

      expect(state.noResults, isTrue);
      expect(state.failed, isTrue);

      final second = state.searchNow('igreja');
      pending[1].complete([_place('Igreja Católica de Nacuto')]);
      await second;

      expect(state.failed, isFalse);
      expect(_names(state), ['Igreja Católica de Nacuto']);
    });

    test('goes back to the suggestions when the text is empty', () async {
      final done = state.searchNow('igreja');
      pending.single.complete([_place('Igreja Católica de Nacuto')]);
      await done;

      await state.searchNow('   ');

      expect(_names(state), ['Aeroporto']);
      expect(state.noResults, isFalse);
      expect(queries, ['igreja']);
    });

    test('ignores a late answer to an older search', () async {
      final first = state.searchNow('igreja');
      final second = state.searchNow('escola');
      expect(queries, ['igreja', 'escola']);

      pending[1].complete([_place('Escola Primária')]);
      await second;
      pending[0].complete([_place('Igreja Católica')]);
      await first;

      expect(_names(state), ['Escola Primária']);
    });

    test('ignores an empty text over a search still running', () async {
      final done = state.searchNow('igreja');
      await state.searchNow('');

      pending.single.complete([_place('Igreja Católica')]);
      await done;

      expect(_names(state), ['Aeroporto']);
    });

    test('gives up on a search that never answers', () async {
      final slow = PlaceSearchState(
        suggestions: const [],
        search: (_) => Completer<List<Map<String, dynamic>>>().future,
        timeout: const Duration(milliseconds: 30),
      );

      await slow.searchNow('igreja');

      expect(slow.failed, isTrue);
      expect(slow.noResults, isTrue);
    });

    test('does not notify after being disposed', () async {
      var notifications = 0;
      state.addListener(() => notifications++);

      final done = state.searchNow('igreja');
      state.dispose();
      pending.single.complete([_place('Igreja Católica de Nacuto')]);
      await done;

      expect(notifications, 0);
    });
  });

  group('PlaceSearchState.savedShape', () {
    test('uses the same format as the map picker', () {
      expect(PlaceSearchState.savedShape(_place('Igreja Católica de Nacuto')), {
        'name': 'Igreja Católica de Nacuto',
        'fullName': 'Igreja Católica de Nacuto, Nampula, Moçambique',
        'lat': -15.1165,
        'lng': 39.2666,
      });
    });

    test('falls back to the full name when there is no name', () {
      final place = _place('Nacuto')..remove('name');

      expect(
        PlaceSearchState.savedShape(place)['name'],
        'Nacuto, Nampula, Moçambique',
      );
    });
  });
}
