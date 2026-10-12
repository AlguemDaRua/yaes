import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:limousineexecutive/passenger/models/saved_place.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';

/// Moradas guardadas do utilizador com sessão iniciada
/// (`users/{uid}/savedLocations`).
///
/// É o único dono destes dados: os ecrãs só lêem daqui. Acompanha a sessão e
/// limpa a lista ao mudar de conta, para nunca mostrar as moradas de outra
/// pessoa.
class SavedPlacesState extends ChangeNotifier {
  SavedPlacesState({
    required ITripRepository repository,
    required IAuthRepository auth,
  }) : _repository = repository {
    _authSubscription = auth.onAuthStateChanged.listen(_onUserChanged);
  }

  final ITripRepository _repository;
  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  String? _uid;
  List<SavedPlace> _places = const [];

  /// Casa, Trabalho e depois as outras. Vazia sem sessão ou sem moradas.
  List<SavedPlace> get places => _places;

  void _onUserChanged(AppUser? user) {
    final uid = user?.uid;
    if (uid == _uid) return;
    _uid = uid;

    _profileSubscription?.cancel();
    _profileSubscription = null;
    _setPlaces(const []);

    if (uid == null) return;
    _profileSubscription = _repository
        .watchProfile(uid)
        .listen(
          (profile) =>
              _setPlaces(SavedPlace.parseAll(profile?['savedLocations'])),
          onError: (Object error) => debugPrint('SavedPlacesState: $error'),
        );
  }

  void _setPlaces(List<SavedPlace> next) {
    if (listEquals(_places, next)) return;
    _places = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
