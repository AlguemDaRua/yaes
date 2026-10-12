import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/models/saved_places_state.dart';
import 'package:limousineexecutive/passenger/widgets/location_search_sheet.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_trip_repository.dart';

/// Repositório cujo perfil já traz as moradas guardadas.
class _RepoWithProfile extends FakeTripRepository {
  _RepoWithProfile(this.profile);

  final Map<String, dynamic>? profile;

  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) =>
      Stream.value(profile);
}

Map<String, dynamic> _profileWithPlaces() => {
  'savedLocations': {
    'home': {
      'name': 'Rua da Casa',
      'fullName': 'Rua da Casa, Nampula',
      'lat': -15.1165,
      'lng': 39.2666,
    },
    '1700000001000': {
      'name': 'Igreja Católica de Nacuto',
      'fullName': 'Igreja Católica de Nacuto, Nampula',
      'lat': -15.12,
      'lng': 39.27,
      'label': 'Igreja',
    },
  },
};

void main() {
  late PassengerState appState;
  late SavedPlacesState savedPlaces;
  var routeCalls = 0;

  setUp(() {
    routeCalls = 0;
    appState = PassengerState(
      repository: FakeTripRepository(),
      auth: FakeAuthRepository(),
      simulateLoading: false,
    );
  });

  tearDown(() {
    appState.dispose();
    savedPlaces.dispose();
  });

  Future<void> pumpSheet(
    WidgetTester tester,
    Map<String, dynamic>? profile,
  ) async {
    savedPlaces = SavedPlacesState(
      repository: _RepoWithProfile(profile),
      auth: FakeAuthRepository()..setUser(AppUser(uid: 'u1')),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PassengerState>.value(value: appState),
          ChangeNotifierProvider<SavedPlacesState>.value(value: savedPlaces),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LocationSearchSheet(
              onRouteChanged: () => routeCalls++,
              onAnimateSheet: (_) {},
            ),
          ),
        ),
      ),
    );
    // As moradas chegam por streams: deixa-as entrar e redesenhar.
    await tester.pumpAndSettle();
  }

  testWidgets('shows the saved places before the other suggestions', (
    tester,
  ) async {
    appState.showDestinationOptions = true;
    await pumpSheet(tester, _profileWithPlaces());

    expect(find.text('Moradas guardadas'), findsOneWidget);
    expect(find.text('Sugestões'), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Igreja'), findsOneWidget);

    final casaTop = tester.getTopLeft(find.text('Casa')).dy;
    final suggestionTop = tester
        .getTopLeft(find.text('Aeroporto de Maputo'))
        .dy;
    expect(casaTop, lessThan(suggestionTop));
  });

  testWidgets('looks exactly as before when there are no saved places', (
    tester,
  ) async {
    appState.showDestinationOptions = true;
    await pumpSheet(tester, {'name': 'Ana'});

    expect(find.text('Moradas guardadas'), findsNothing);
    expect(find.text('Sugestões'), findsNothing);
    expect(find.text('Aeroporto de Maputo'), findsOneWidget);
  });

  testWidgets('does not show saved places when the destination is not active', (
    tester,
  ) async {
    await pumpSheet(tester, _profileWithPlaces());

    expect(find.text('Moradas guardadas'), findsNothing);
    expect(find.text('Casa'), findsNothing);
    expect(find.text('Aeroporto de Maputo'), findsOneWidget);
  });

  testWidgets('tapping a saved place sets the destination', (tester) async {
    appState.showDestinationOptions = true;
    appState.fromAddress = 'Origem';
    await pumpSheet(tester, _profileWithPlaces());

    await tester.tap(find.text('Casa'));
    await tester.pump();

    expect(appState.toAddress, 'Rua da Casa');
    expect(appState.destinationLocation, const LatLng(-15.1165, 39.2666));
    expect(appState.controllerDestination.text, 'Rua da Casa');
    expect(appState.showDestinationOptions, isFalse);
    expect(routeCalls, 1);
  });

  testWidgets('tapping a regular suggestion still sets the destination', (
    tester,
  ) async {
    appState.showDestinationOptions = true;
    appState.fromAddress = 'Origem';
    await pumpSheet(tester, {'name': 'Ana'});

    await tester.tap(find.text('Aeroporto de Maputo'));
    await tester.pump();

    expect(appState.toAddress, 'Aeroporto de Maputo');
    expect(appState.destinationLocation, const LatLng(-25.9218, 32.5734));
    expect(appState.controllerDestination.text, 'Aeroporto de Maputo');
    expect(appState.showDestinationOptions, isFalse);
    expect(routeCalls, 1);
  });
}
