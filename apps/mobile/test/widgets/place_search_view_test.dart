import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/widgets/place_search_view.dart';

const _hint = 'Escreve pelo menos 3 letras e carrega em pesquisar.';

Map<String, dynamic> _place(String name) => {
  'name': name,
  'fullName': '$name, Nampula, Moçambique',
  'type': 'place_of_worship',
  'latlong': const LatLng(-15.1165, 39.2666),
};

void main() {
  late List<String> queries;
  late List<Completer<List<Map<String, dynamic>>>> pending;
  late List<Map<String, dynamic>> selected;
  var mapTaps = 0;

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
    selected = [];
    mapTaps = 0;
  });

  Future<void> pumpView(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaceSearchView(
            search: fakeSearch,
            onSelected: selected.add,
            onPickOnMap: () => mapTaps++,
          ),
        ),
      ),
    );
  }

  // Escreve o texto e carrega no botão de pesquisar.
  Future<void> typeAndSearch(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pump();
  }

  testWidgets('starts with a hint and the map option, without searching', (
    tester,
  ) async {
    await pumpView(tester);

    expect(find.text(_hint), findsOneWidget);
    expect(find.text('Escolher no mapa'), findsOneWidget);
    expect(queries, isEmpty);
  });

  testWidgets('does not search with fewer than 3 letters', (tester) async {
    await pumpView(tester);

    await typeAndSearch(tester, 'ig');

    expect(queries, isEmpty);
    expect(find.text(_hint), findsOneWidget);
  });

  testWidgets('searches the trimmed text and shows loading until it answers', (
    tester,
  ) async {
    await pumpView(tester);

    await typeAndSearch(tester, '  igreja  ');

    expect(queries, ['igreja']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.single.complete([_place('Igreja Católica de Nacuto')]);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Igreja Católica de Nacuto'), findsOneWidget);
  });

  testWidgets('searches when the keyboard search key is pressed', (
    tester,
  ) async {
    await pumpView(tester);

    await tester.enterText(find.byType(TextField), 'escola');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(queries, ['escola']);

    pending.single.complete([]);
    await tester.pump();
  });

  testWidgets('tapping a result hands over the place in the saved format', (
    tester,
  ) async {
    await pumpView(tester);
    await typeAndSearch(tester, 'igreja');
    pending.single.complete([_place('Igreja Católica de Nacuto')]);
    await tester.pump();

    await tester.tap(find.text('Igreja Católica de Nacuto'));

    expect(selected, [
      {
        'name': 'Igreja Católica de Nacuto',
        'fullName': 'Igreja Católica de Nacuto, Nampula, Moçambique',
        'lat': -15.1165,
        'lng': 39.2666,
      },
    ]);
  });

  testWidgets('shows a message when nothing is found', (tester) async {
    await pumpView(tester);
    await typeAndSearch(tester, 'xyzxyz');

    pending.single.complete([]);
    await tester.pump();

    expect(find.textContaining('Sem resultados para “xyzxyz”'), findsOneWidget);
    expect(find.text('Escolher no mapa'), findsOneWidget);
  });

  testWidgets('shows an error and tries again', (tester) async {
    await pumpView(tester);
    await typeAndSearch(tester, 'igreja');

    pending.single.completeError(Exception('sem rede'));
    await tester.pump();

    expect(find.textContaining('Não foi possível pesquisar'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pump();

    expect(queries, ['igreja', 'igreja']);

    pending.last.complete([_place('Igreja Católica de Nacuto')]);
    await tester.pump();

    expect(find.text('Igreja Católica de Nacuto'), findsOneWidget);
  });

  testWidgets('gives up on a search that never answers', (tester) async {
    await pumpView(tester);
    await typeAndSearch(tester, 'igreja');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 16));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('ignores a late answer to an older search', (tester) async {
    await pumpView(tester);

    await typeAndSearch(tester, 'igreja');
    await typeAndSearch(tester, 'escola');
    expect(queries, ['igreja', 'escola']);

    pending[1].complete([_place('Escola Primária')]);
    await tester.pump();
    pending[0].complete([_place('Igreja Católica')]);
    await tester.pump();

    expect(find.text('Escola Primária'), findsOneWidget);
    expect(find.text('Igreja Católica'), findsNothing);
  });

  testWidgets('the map option is always available', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Escolher no mapa'));

    expect(mapTaps, 1);
  });
}
