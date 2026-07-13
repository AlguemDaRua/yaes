import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_trip_repository.dart';

void main() {
  late PassengerState state;
  late FakeTripRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeTripRepository();
    state = PassengerState(
        repository: fakeRepo, auth: FakeAuthRepository(), simulateLoading: false);
  });

  group('PassengerState stops management', () {
    test('starts with empty stops', () {
      expect(state.stops, isEmpty);
    });

    test('addStop appends a stop', () {
      state.addStop({'name': 'Paragem A', 'latlong': const LatLng(-25.9, 32.5)});
      expect(state.stops.length, 1);
      expect(state.stops.first['name'], 'Paragem A');
    });

    test('removeStopAt removes the correct stop', () {
      state.addStop({'name': 'A'});
      state.addStop({'name': 'B'});
      state.addStop({'name': 'C'});
      state.removeStopAt(1);
      expect(state.stops.length, 2);
      expect(state.stops[0]['name'], 'A');
      expect(state.stops[1]['name'], 'C');
    });

    test('removeStopAt out-of-bounds does nothing', () {
      state.addStop({'name': 'A'});
      state.removeStopAt(5);
      expect(state.stops.length, 1);
    });

    test('clearStops empties the list', () {
      state.addStop({'name': 'A'});
      state.addStop({'name': 'B'});
      state.clearStops();
      expect(state.stops, isEmpty);
    });

    test('insertStop inserts at correct position', () {
      state.addStop({'name': 'A'});
      state.addStop({'name': 'C'});
      state.insertStop(1, {'name': 'B'});
      expect(state.stops[1]['name'], 'B');
      expect(state.stops.length, 3);
    });

    test('setStops replaces the list', () {
      state.addStop({'name': 'old'});
      state.setStops([{'name': 'X'}, {'name': 'Y'}]);
      expect(state.stops.length, 2);
      expect(state.stops[0]['name'], 'X');
    });
  });

  group('PassengerState location', () {
    test('destinationLocation starts null', () {
      expect(state.destinationLocation, isNull);
    });

    test('setting destinationLocation updates state', () {
      state.destinationLocation = const LatLng(-25.9692, 32.5732);
      expect(state.destinationLocation, isNotNull);
    });

    test('distanceKm starts at 0', () {
      expect(state.distanceKm, 0.0);
    });

    test('durationMin starts at 0', () {
      expect(state.durationMin, 0);
    });

    test('setting distanceKm updates correctly', () {
      state.distanceKm = 12.5;
      expect(state.distanceKm, 12.5);
    });

    test('setting durationMin updates correctly', () {
      state.durationMin = 20;
      expect(state.durationMin, 20);
    });

    test('fromAddress and toAddress default to empty', () {
      expect(state.fromAddress, '');
      expect(state.toAddress, '');
    });
  });

  group('PassengerState price', () {
    test('estimatedPrice starts at 0', () {
      expect(state.estimatedPrice, 0.0);
    });

    test('setting estimatedPrice updates correctly', () {
      state.estimatedPrice = 350.0;
      expect(state.estimatedPrice, 350.0);
    });

    test('cachedPricing starts null', () {
      expect(state.cachedPricing, isNull);
    });

    test('fetchServerPrice does nothing when distanceKm <= 0', () async {
      state.distanceKm = 0;
      await state.fetchServerPrice();
      // Price stays at 0, no crash
      expect(state.estimatedPrice, 0.0);
    });
  });

  group('PassengerState payment', () {
    test('isPaymentSelected starts false', () {
      expect(state.isPaymentSelected, isFalse);
    });

    test('paymentMethod can be set', () {
      state.paymentMethod = 'cash';
      expect(state.paymentMethod, 'cash');
    });

    test('isPaymentSelected can be toggled', () {
      state.isPaymentSelected = true;
      expect(state.isPaymentSelected, isTrue);
      state.isPaymentSelected = false;
      expect(state.isPaymentSelected, isFalse);
    });
  });

  group('PassengerState favorites', () {
    final car = {'name': 'Mercedes S500', 'seats': '4'};

    test('isFavorite returns false initially', () {
      expect(state.isFavorite('Mercedes S500'), isFalse);
    });

    test('addFavorite marks a car as favorite', () {
      state.addFavorite(car);
      expect(state.isFavorite('Mercedes S500'), isTrue);
    });

    test('addFavorite is idempotent (no duplicates)', () {
      state.addFavorite(car);
      state.addFavorite(car);
      expect(state.favoriteCars.length, 1);
    });

    test('removeFavorite removes by name', () {
      state.addFavorite(car);
      state.removeFavorite('Mercedes S500');
      expect(state.isFavorite('Mercedes S500'), isFalse);
    });

    test('removeFavorite on non-existent car is safe', () {
      state.removeFavorite('NonExistent');
      expect(state.favoriteCars, isEmpty);
    });
  });

  group('PassengerState agendas', () {
    final agenda = {
      'fromAddress': 'Maputo Airport',
      'toAddress': 'Hotel Polana',
      'selectedCar': 'Mercedes S500',
      'time': DateTime(2026, 6, 1, 10, 0),
    };

    test('agendas starts empty', () {
      expect(state.agendas, isEmpty);
    });

    test('addAgenda appends and calls createSchedule', () {
      state.addAgenda(agenda);
      expect(state.agendas.length, 1);
      expect(fakeRepo.createScheduleCallCount, 1);
    });

    test('addAgenda sets newScheduleCreated to true', () {
      state.addAgenda(agenda);
      expect(state.newScheduleCreated, isTrue);
    });

    test('removeAgendaAt removes and returns the item', () {
      state.addAgenda(agenda);
      final removed = state.removeAgendaAt(0);
      expect(state.agendas, isEmpty);
      expect(removed?['toAddress'], 'Hotel Polana');
    });

    test('removeAgendaAt out-of-bounds returns null', () {
      final result = state.removeAgendaAt(99);
      expect(result, isNull);
    });

    test('rescheduleAgendaAt updates the time', () {
      state.addAgenda(agenda);
      final newTime = DateTime(2026, 7, 1, 9, 0);
      state.rescheduleAgendaAt(index: 0, time: newTime);
      expect(state.agendas[0]['time'], newTime);
    });
  });

  group('PassengerState UI flags', () {
    test('showRoute starts false', () {
      expect(state.showRoute, isFalse);
    });

    test('showRoute can be set', () {
      state.showRoute = true;
      expect(state.showRoute, isTrue);
    });

    test('showDestinationOptions starts false', () {
      expect(state.showDestinationOptions, isFalse);
    });

    test('showPickupOptions starts false', () {
      expect(state.showPickupOptions, isFalse);
    });

    test('selectedCarType starts empty', () {
      expect(state.selectedCarType, '');
    });

    test('selectedCarType can be set', () {
      state.selectedCarType = 'luxury';
      expect(state.selectedCarType, 'luxury');
    });
  });

  group('PassengerState address list', () {
    test('address list has default POIs', () {
      expect(state.address.isNotEmpty, isTrue);
    });

    test('address setter replaces the list', () {
      state.address = [{'name': 'New Place', 'latlong': const LatLng(-25.9, 32.5)}];
      expect(state.address.length, 1);
      expect(state.address.first['name'], 'New Place');
    });
  });

  group('PassengerState notifyListeners', () {
    test('setters fire change notifications', () {
      int callCount = 0;
      state.addListener(() => callCount++);

      state.fromAddress = 'Test';
      state.toAddress = 'Dest';
      state.distanceKm = 5.0;

      expect(callCount, 3);
      state.removeListener(() {});
    });
  });
}
