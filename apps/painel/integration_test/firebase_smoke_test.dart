// Smoke test contra Firebase emulators. Skippado por defeito;
// activar com `--dart-define=USE_EMULATOR_TESTS=true`:
//
//   flutter test integration_test/firebase_smoke_test.dart \
//     --dart-define=USE_EMULATOR_TESTS=true
//
// Pré-requisitos: emulators ligados + seed corrido.
//   cd ya-app && firebase emulators:start
//   dart run tool/seed.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ya_painel/firebase_options.dart';

const bool _runEmulatorTests = bool.fromEnvironment(
  'USE_EMULATOR_TESTS',
);

void main() {
  setUpAll(() async {
    if (!_runEmulatorTests) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  });

  testWidgets(
    'emulator: lê dados do partner seed',
    (tester) async {
      final DataSnapshot snap =
          await FirebaseDatabase.instance.ref('partners/ptr-maputo-exec').get();
      expect(
        snap.exists,
        isTrue,
        reason: 'Seed não corrido? Corre `dart run tool/seed.dart`.',
      );
      final Map<dynamic, dynamic> partner =
          Map<dynamic, dynamic>.from(snap.value as Map);
      expect(partner['name'], 'Maputo Executive');
      expect(partner['status'], 'active');
    },
    skip: !_runEmulatorTests,
  );

  testWidgets(
    'emulator: drivers do partner são listáveis',
    (tester) async {
      final DataSnapshot snap = await FirebaseDatabase.instance
          .ref('users')
          .orderByChild('partnerId')
          .equalTo('ptr-maputo-exec')
          .get();
      expect(snap.exists, isTrue);
      final Map<dynamic, dynamic> users =
          Map<dynamic, dynamic>.from(snap.value as Map);
      final int drivers = users.values
          .where((dynamic v) => (v as Map)['type'] == 'driver')
          .length;
      expect(drivers, greaterThanOrEqualTo(5));
    },
    skip: !_runEmulatorTests,
  );
}
