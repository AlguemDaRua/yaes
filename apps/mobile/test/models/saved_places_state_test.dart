import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/passenger/models/saved_places_state.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_trip_repository.dart';

/// Sessão controlável: o teste decide quando o utilizador entra e sai.
class _ControllableAuth extends FakeAuthRepository {
  final controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get onAuthStateChanged => controller.stream;
}

/// Perfis controláveis: o teste decide o que cada utilizador "recebe".
class _ControllableProfiles extends FakeTripRepository {
  final controllers = <String, StreamController<Map<String, dynamic>?>>{};

  StreamController<Map<String, dynamic>?> _of(String uid) =>
      controllers.putIfAbsent(
        uid,
        () => StreamController<Map<String, dynamic>?>.broadcast(),
      );

  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) => _of(uid).stream;

  void emit(String uid, Map<String, dynamic>? profile) => _of(uid).add(profile);

  void emitError(String uid, Object error) => _of(uid).addError(error);
}

Map<String, dynamic> _place(String name) => {
  'name': name,
  'fullName': '$name, Nampula',
  'lat': -15.1165,
  'lng': 39.2666,
};

void main() {
  late _ControllableAuth auth;
  late _ControllableProfiles repo;
  late SavedPlacesState state;

  // Deixa os eventos dos streams chegarem ao estado.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    auth = _ControllableAuth();
    repo = _ControllableProfiles();
    state = SavedPlacesState(repository: repo, auth: auth);
  });

  tearDown(() {
    state.dispose();
    auth.controller.close();
    for (final controller in repo.controllers.values) {
      controller.close();
    }
  });

  test('starts empty and does not read any profile before sign-in', () async {
    await settle();

    expect(state.places, isEmpty);
    expect(repo.controllers, isEmpty);
  });

  test('loads the saved places of the signed-in user', () async {
    auth.controller.add(AppUser(uid: 'u1'));
    await settle();
    repo.emit('u1', {
      'name': 'Ana',
      'savedLocations': {'home': _place('Rua A'), '1': _place('Mercado')},
    });
    await settle();

    expect(state.places.map((p) => p.title), ['Casa', 'Mercado']);
  });

  test('updates when the user saves or removes a place', () async {
    auth.controller.add(AppUser(uid: 'u1'));
    await settle();
    repo.emit('u1', {
      'savedLocations': {'home': _place('Rua A')},
    });
    await settle();
    expect(state.places, hasLength(1));

    repo.emit('u1', {
      'savedLocations': {'home': _place('Rua A'), 'work': _place('Rua B')},
    });
    await settle();
    expect(state.places.map((p) => p.id), ['home', 'work']);

    repo.emit('u1', {'name': 'Ana'});
    await settle();
    expect(state.places, isEmpty);
  });

  test('clears the places when the user signs out', () async {
    auth.controller.add(AppUser(uid: 'u1'));
    await settle();
    repo.emit('u1', {
      'savedLocations': {'home': _place('Rua A')},
    });
    await settle();
    expect(state.places, isNotEmpty);

    auth.controller.add(null);
    await settle();
    expect(state.places, isEmpty);

    // O perfil antigo já não é ouvido.
    repo.emit('u1', {
      'savedLocations': {'home': _place('Rua A')},
    });
    await settle();
    expect(state.places, isEmpty);
  });

  test('never shows the places of the previous account', () async {
    auth.controller.add(AppUser(uid: 'u1'));
    await settle();
    repo.emit('u1', {
      'savedLocations': {'home': _place('Casa da Ana')},
    });
    await settle();

    auth.controller.add(AppUser(uid: 'u2'));
    await settle();
    expect(state.places, isEmpty);

    repo.emit('u2', {
      'savedLocations': {'work': _place('Escritório do Rui')},
    });
    await settle();
    expect(state.places.map((p) => p.name), ['Escritório do Rui']);
  });

  test('only notifies when the places really change', () async {
    var notifications = 0;
    state.addListener(() => notifications++);

    auth.controller.add(AppUser(uid: 'u1'));
    await settle();
    final profile = {
      'savedLocations': {'home': _place('Rua A')},
    };
    repo.emit('u1', profile);
    await settle();
    expect(notifications, 1);

    // O perfil mudou noutra coisa (ex.: avaliação), as moradas são as mesmas.
    repo.emit('u1', {...profile, 'rating': 4.8});
    await settle();
    expect(notifications, 1);
  });

  test('keeps working when reading the profile fails', () async {
    auth.controller.add(AppUser(uid: 'u1'));
    await settle();

    repo.emitError('u1', 'permission-denied');
    await settle();
    expect(state.places, isEmpty);

    repo.emit('u1', {
      'savedLocations': {'home': _place('Rua A')},
    });
    await settle();
    expect(state.places, hasLength(1));
  });
}
