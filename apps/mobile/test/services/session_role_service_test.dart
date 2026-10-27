import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/services/session_role_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  group('SessionRoleService', () {
    late _RoleAuthRepository auth;
    late _MemoryRoleCache cache;
    late SessionRoleService service;

    setUp(() {
      auth = _RoleAuthRepository();
      cache = _MemoryRoleCache();
      service = SessionRoleService(auth: auth, cache: cache);
    });

    for (final type in ['driver', 'passenger']) {
      test('resolves and caches an authenticated $type account', () async {
        auth.type = type;

        expect(await service.resolveType(AppUser(uid: 'account')), type);
        expect(cache.values, {'account': type});
        expect(auth.requestedUids, ['account']);
        expect(auth.signOutCalls, 0);
      });
    }

    test('uses only the same account cache while offline', () async {
      auth.failure = StateError('offline');
      cache.values.addAll({'driver-a': 'driver', 'passenger-b': 'passenger'});

      expect(await service.resolveType(AppUser(uid: 'driver-a')), 'driver');
      expect(cache.readUids, ['driver-a']);
      expect(auth.signOutCalls, 0);
    });

    test(
      'does not reuse the previous account role after changing UID',
      () async {
        cache.values['driver-a'] = 'driver';
        auth.failure = StateError('offline');

        await expectLater(
          service.resolveType(AppUser(uid: 'passenger-b')),
          throwsA(isA<SessionRoleUnavailableException>()),
        );
        expect(cache.readUids, ['passenger-b']);
        expect(auth.signOutCalls, 0);
      },
    );

    test('a fresh profile overrides an outdated role in the cache', () async {
      cache.values['account'] = 'driver';
      auth.type = 'passenger';

      expect(await service.resolveType(AppUser(uid: 'account')), 'passenger');
      expect(cache.values['account'], 'passenger');
    });

    test('cache write failure does not reject a valid profile', () async {
      auth.type = 'driver';
      cache.writeFailure = StateError('storage unavailable');

      expect(await service.resolveType(AppUser(uid: 'account')), 'driver');
      expect(cache.readUids, isEmpty);
      expect(auth.signOutCalls, 0);
    });

    test('cache read failure produces a controlled retryable error', () async {
      auth.failure = StateError('offline');
      cache.readFailure = StateError('storage unavailable');

      await expectLater(
        service.resolveType(AppUser(uid: 'account')),
        throwsA(isA<SessionRoleUnavailableException>()),
      );
      expect(auth.signOutCalls, 0);
    });

    test(
      'unknown offline accounts are not assigned the passenger role',
      () async {
        auth.failure = StateError('offline');

        await expectLater(
          service.resolveType(AppUser(uid: 'account')),
          throwsA(isA<SessionRoleUnavailableException>()),
        );
        expect(cache.values, isEmpty);
        expect(auth.signOutCalls, 0);
      },
    );

    test('a profile timeout falls back to the account cache', () async {
      auth.pendingType = Completer<String>();
      cache.values['account'] = 'driver';
      service = SessionRoleService(
        auth: auth,
        cache: cache,
        profileTimeout: const Duration(milliseconds: 10),
      );

      expect(await service.resolveType(AppUser(uid: 'account')), 'driver');
      auth.pendingType!.complete('passenger');
      await Future<void>.delayed(Duration.zero);
      expect(cache.values['account'], 'driver');
    });

    test('invalid profile and cache values require retry', () async {
      auth.type = 'admin';
      cache.values['account'] = 'partner';

      await expectLater(
        service.resolveType(AppUser(uid: 'account')),
        throwsA(isA<SessionRoleUnavailableException>()),
      );
      expect(cache.values['account'], 'partner');
    });

    test('invalid remote role can use the same account valid cache', () async {
      auth.type = '';
      cache.values['account'] = 'passenger';

      expect(await service.resolveType(AppUser(uid: 'account')), 'passenger');
    });

    test('empty UID is rejected without looking up another account', () async {
      await expectLater(
        service.resolveType(AppUser(uid: '')),
        throwsA(isA<SessionRoleUnavailableException>()),
      );
      expect(auth.requestedUids, isEmpty);
      expect(cache.readUids, isEmpty);
    });

    test('clear removes only the requested account hint', () async {
      cache.values.addAll({'driver-a': 'driver', 'passenger-b': 'passenger'});

      await service.clear('driver-a');

      expect(cache.values, {'passenger-b': 'passenger'});
      expect(auth.signOutCalls, 0);
    });

    test('cache cleanup failure does not block logout', () async {
      cache.removeFailure = StateError('storage unavailable');

      await expectLater(service.clear('account'), completes);
    });
  });

  group('SharedPreferencesSessionRoleCache', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'type': 'legacy-unscoped-role',
        'unrelated': true,
      });
    });

    test(
      'persists hints per UID without reading the old global type',
      () async {
        final cache = SharedPreferencesSessionRoleCache();
        expect(await cache.read('account-a'), isNull);

        await cache.write('account-a', 'driver');
        await cache.write('account-b', 'passenger');

        final reopenedCache = SharedPreferencesSessionRoleCache();
        expect(await reopenedCache.read('account-a'), 'driver');
        expect(await reopenedCache.read('account-b'), 'passenger');
        expect(await reopenedCache.read('account-c'), isNull);
        expect(
          (await SharedPreferences.getInstance()).get('unrelated'),
          isTrue,
        );
      },
    );

    test('removes only the requested UID', () async {
      final cache = SharedPreferencesSessionRoleCache();
      await cache.write('account-a', 'driver');
      await cache.write('account-b', 'passenger');

      await cache.remove('account-a');

      expect(await cache.read('account-a'), isNull);
      expect(await cache.read('account-b'), 'passenger');
    });
  });
}

class _RoleAuthRepository extends FakeAuthRepository {
  String type = 'passenger';
  Object? failure;
  Completer<String>? pendingType;
  final List<String> requestedUids = [];
  int signOutCalls = 0;

  @override
  Future<String> getUserType(String uid) async {
    requestedUids.add(uid);
    if (failure != null) throw failure!;
    return pendingType?.future ?? type;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await super.signOut();
  }
}

class _MemoryRoleCache implements SessionRoleCache {
  final Map<String, String> values = {};
  final List<String> readUids = [];
  Object? readFailure;
  Object? writeFailure;
  Object? removeFailure;

  @override
  Future<String?> read(String uid) async {
    readUids.add(uid);
    if (readFailure != null) throw readFailure!;
    return values[uid];
  }

  @override
  Future<void> write(String uid, String type) async {
    if (writeFailure != null) throw writeFailure!;
    values[uid] = type;
  }

  @override
  Future<void> remove(String uid) async {
    if (removeFailure != null) throw removeFailure!;
    values.remove(uid);
  }
}
