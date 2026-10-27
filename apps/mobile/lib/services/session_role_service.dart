import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';

/// Stores a UI routing hint for an already authenticated account.
///
/// This cache never establishes a session or grants driver permissions.
abstract class SessionRoleCache {
  Future<String?> read(String uid);
  Future<void> write(String uid, String type);
  Future<void> remove(String uid);
}

class SharedPreferencesSessionRoleCache implements SessionRoleCache {
  static String _key(String uid) => 'yaapp.session_role.v1.$uid';

  @override
  Future<String?> read(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key(uid));
  }

  @override
  Future<void> write(String uid, String type) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(_key(uid), type)) {
      throw StateError('Não foi possível guardar o tipo de conta localmente.');
    }
  }

  @override
  Future<void> remove(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(_key(uid))) {
      throw StateError('Não foi possível limpar o tipo de conta localmente.');
    }
  }
}

class SessionRoleUnavailableException implements Exception {
  const SessionRoleUnavailableException();

  @override
  String toString() =>
      'Não foi possível carregar a sua conta. Verifique a ligação e tente novamente.';
}

class SessionRoleService {
  SessionRoleService({
    required IAuthRepository auth,
    SessionRoleCache? cache,
    Duration profileTimeout = const Duration(seconds: 4),
  }) : _auth = auth,
       _cache = cache ?? SharedPreferencesSessionRoleCache(),
       _profileTimeout = profileTimeout;

  final IAuthRepository _auth;
  final SessionRoleCache _cache;
  final Duration _profileTimeout;

  Future<String> resolveType(AppUser user) async {
    if (user.uid.isEmpty) throw const SessionRoleUnavailableException();

    String? remoteType;
    try {
      final type = await _auth.getUserType(user.uid).timeout(_profileTimeout);
      if (_isSupported(type)) remoteType = type;
    } catch (error) {
      debugPrint('Não foi possível consultar o tipo da conta: $error');
    }

    if (remoteType != null) {
      try {
        await _cache.write(user.uid, remoteType).timeout(_profileTimeout);
      } catch (error) {
        debugPrint('Não foi possível atualizar o tipo de conta local: $error');
      }
      return remoteType;
    }

    try {
      final cachedType = await _cache.read(user.uid).timeout(_profileTimeout);
      if (cachedType != null && _isSupported(cachedType)) return cachedType;
    } catch (error) {
      debugPrint('Não foi possível ler o tipo de conta local: $error');
    }

    throw const SessionRoleUnavailableException();
  }

  Future<void> clear(String uid) async {
    try {
      await _cache.remove(uid).timeout(_profileTimeout);
    } catch (error) {
      debugPrint('Não foi possível limpar o tipo de conta local: $error');
    }
  }

  static bool _isSupported(String type) =>
      type == 'driver' || type == 'passenger';
}
