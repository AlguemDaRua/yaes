import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limousineexecutive/authentication/auth_session_gate.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';

import '../fakes/fake_auth_repository.dart';

const _signedInKey = ValueKey('signed-in-screen');
const _signedOutKey = ValueKey('signed-out-screen');
const _loadingKey = ValueKey('restoring-session');

void main() {
  testWidgets('opens an existing session immediately and keeps watching auth', (
    tester,
  ) async {
    final repository = _ControlledAuthRepository(
      initialUser: AppUser(uid: 'passenger-a'),
    );

    await _mountGate(tester, repository);

    expect(find.byKey(_signedInKey), findsOneWidget);
    expect(find.byKey(_signedOutKey), findsNothing);
    expect(find.byKey(_loadingKey), findsNothing);
    expect(repository.streamReads, 1);
    expect(repository.hasListener, isTrue);
  });

  testWidgets(
    'reopening the app restores persisted credentials without signing out',
    (tester) async {
      final repository = _ControlledAuthRepository(
        initialUser: AppUser(uid: 'persisted-passenger'),
      );
      await _mountGate(tester, repository);
      expect(find.byKey(_signedInKey), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(repository.hasListener, isFalse);
      expect(repository.currentUser?.uid, 'persisted-passenger');
      expect(repository.signOutCalls, 0);

      await _mountGate(tester, repository, registerTearDown: false);

      expect(repository.streamReads, 2);
      expect(repository.hasListener, isTrue);
      expect(repository.signOutCalls, 0);
      expect(find.byKey(_signedInKey), findsOneWidget);
      expect(find.byKey(_signedOutKey), findsNothing);
      expect(find.byKey(_loadingKey), findsNothing);
    },
  );

  testWidgets(
    'waits for restoration after the first null instead of showing OTP',
    (tester) async {
      final repository = _ControlledAuthRepository();
      await _mountGate(tester, repository);

      repository.emitUser(null);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(_loadingKey), findsOneWidget);
      expect(find.byKey(_signedOutKey), findsNothing);

      repository.emitUser(AppUser(uid: 'restored-passenger'));
      await tester.pump();

      expect(find.byKey(_signedInKey), findsOneWidget);
      expect(find.byKey(_signedOutKey), findsNothing);
      expect(find.byKey(_loadingKey), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(_signedInKey), findsOneWidget);
      expect(find.byKey(_signedOutKey), findsNothing);
    },
  );

  testWidgets(
    'enters automatically when auth arrives from the signed-out screen',
    (tester) async {
      final repository = _ControlledAuthRepository();
      await _mountGate(tester, repository);

      repository.emitUser(null);
      await tester.pump(const Duration(milliseconds: 501));

      expect(find.byKey(_signedOutKey), findsOneWidget);
      expect(find.byKey(_signedInKey), findsNothing);

      repository.emitUser(AppUser(uid: 'new-passenger'));
      await tester.pump();

      expect(find.byKey(_signedInKey), findsOneWidget);
      expect(find.byKey(_signedOutKey), findsNothing);
      expect(repository.streamReads, 1);
    },
  );

  testWidgets('an explicit null after a confirmed user signs out immediately', (
    tester,
  ) async {
    final repository = _ControlledAuthRepository(
      initialUser: AppUser(uid: 'passenger-a'),
    );
    await _mountGate(tester, repository);
    expect(find.byKey(_signedInKey), findsOneWidget);

    repository.emitUser(null);
    await tester.pump();

    expect(find.byKey(_signedOutKey), findsOneWidget);
    expect(find.byKey(_signedInKey), findsNothing);
    expect(find.byKey(_loadingKey), findsNothing);
  });

  testWidgets('a timeout offers retry and accepts a late restored user', (
    tester,
  ) async {
    final repository = _ControlledAuthRepository();
    await _mountGate(tester, repository);

    await tester.pump(const Duration(seconds: 9));

    expect(find.text('Não foi possível recuperar a sessão'), findsOneWidget);
    expect(find.byKey(_signedOutKey), findsNothing);
    expect(find.byKey(_signedInKey), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Tentar novamente'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Tentar novamente'));
    await tester.pump();

    expect(repository.streamReads, 2);
    expect(repository.cancelledSubscriptions, 1);
    expect(repository.hasListener, isTrue);
    expect(find.byKey(_loadingKey), findsOneWidget);
    expect(find.byKey(_signedOutKey), findsNothing);

    repository.emitUser(AppUser(uid: 'late-restored-passenger'));
    await tester.pump();

    expect(find.byKey(_signedInKey), findsOneWidget);
    expect(find.byKey(_signedOutKey), findsNothing);
    expect(find.text('Não foi possível recuperar a sessão'), findsNothing);
  });

  testWidgets(
    'an auth error without a user stays recoverable and accepts late auth',
    (tester) async {
      final repository = _ControlledAuthRepository();
      await _mountGate(tester, repository);

      repository.emitError(StateError('Authentication stream unavailable'));
      await tester.pump();

      expect(find.text('Não foi possível recuperar a sessão'), findsOneWidget);
      expect(find.byKey(_signedOutKey), findsNothing);
      expect(
        find.widgetWithText(FilledButton, 'Tentar novamente'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      repository.emitUser(AppUser(uid: 'recovered-passenger'));
      await tester.pump();

      expect(find.byKey(_signedInKey), findsOneWidget);
      expect(find.byKey(_signedOutKey), findsNothing);
      expect(find.text('Não foi possível recuperar a sessão'), findsNothing);
      expect(repository.streamReads, 1);
    },
  );

  testWidgets('a transient auth error preserves an already confirmed session', (
    tester,
  ) async {
    final repository = _ControlledAuthRepository(
      initialUser: AppUser(uid: 'passenger-a'),
    );
    await _mountGate(tester, repository);

    repository.emitError(StateError('Temporary connection loss'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));

    expect(find.byKey(_signedInKey), findsOneWidget);
    expect(find.byKey(_signedOutKey), findsNothing);
    expect(find.byKey(_loadingKey), findsNothing);
    expect(find.text('Não foi possível recuperar a sessão'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps state for the same UID and recreates it for another user',
    (tester) async {
      var mountedSessions = 0;
      final repository = _ControlledAuthRepository(
        initialUser: AppUser(uid: 'passenger-a'),
      );
      await _mountGate(
        tester,
        repository,
        signedInChild: _SessionCounter(onMounted: () => mountedSessions++),
      );

      expect(mountedSessions, 1);
      await tester.tap(find.widgetWithText(TextButton, 'Incrementar'));
      await tester.pump();
      expect(find.text('Estado da sessão: 1'), findsOneWidget);

      repository.emitUser(AppUser(uid: 'passenger-a'));
      await tester.pump();

      expect(mountedSessions, 1);
      expect(find.text('Estado da sessão: 1'), findsOneWidget);

      repository.emitUser(AppUser(uid: 'passenger-b'));
      await tester.pump();

      expect(mountedSessions, 2);
      expect(find.text('Estado da sessão: 0'), findsOneWidget);
      expect(find.text('Estado da sessão: 1'), findsNothing);
      expect(find.byKey(_signedOutKey), findsNothing);
    },
  );

  testWidgets(
    'isolates login and OTP navigation from the private app navigator',
    (tester) async {
      final repository = _ControlledAuthRepository();
      final privateNavigatorKey = GlobalKey<NavigatorState>();
      const otpKey = ValueKey('otp-screen');
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await repository.close();
      });

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: privateNavigatorKey,
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: const Scaffold(body: Text('Área privada', key: _signedInKey)),
          builder: (context, child) => AuthSessionGate(
            authRepository: repository,
            signedInChild: child!,
            loadingChild: const Scaffold(
              body: Text('A recuperar sessão', key: _loadingKey),
            ),
            signedOutChild: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (context) {
                  if (settings.name == '/otp') {
                    return const Scaffold(
                      body: Text('Confirmar código SMS', key: otpKey),
                    );
                  }
                  return Scaffold(
                    body: Column(
                      children: [
                        const Text('Entrar na conta', key: _signedOutKey),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/otp'),
                          child: const Text('Pedir código'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      repository.emitUser(null);
      await tester.pump(const Duration(milliseconds: 501));
      await tester.pumpAndSettle();

      expect(find.byKey(_signedOutKey), findsOneWidget);
      expect(find.byKey(_signedInKey), findsNothing);
      expect(privateNavigatorKey.currentState, isNull);

      await tester.tap(find.widgetWithText(TextButton, 'Pedir código'));
      await tester.pumpAndSettle();

      expect(find.byKey(otpKey), findsOneWidget);
      expect(find.byKey(_signedInKey), findsNothing);
      expect(privateNavigatorKey.currentState, isNull);

      repository.emitUser(AppUser(uid: 'authenticated-passenger'));
      await tester.pumpAndSettle();

      expect(find.byKey(_signedInKey), findsOneWidget);
      expect(find.byKey(otpKey), findsNothing);
      expect(find.byKey(_signedOutKey), findsNothing);
      expect(privateNavigatorKey.currentState, isNotNull);

      repository.emitUser(null);
      await tester.pumpAndSettle();

      expect(find.byKey(_signedOutKey), findsOneWidget);
      expect(find.byKey(otpKey), findsNothing);
      expect(find.byKey(_signedInKey), findsNothing);
      expect(privateNavigatorKey.currentState, isNull);
      expect(repository.streamReads, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _mountGate(
  WidgetTester tester,
  _ControlledAuthRepository repository, {
  Widget? signedInChild,
  bool registerTearDown = true,
}) async {
  if (registerTearDown) {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await repository.close();
    });
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: AuthSessionGate(
        authRepository: repository,
        signedInChild:
            signedInChild ??
            const Scaffold(body: Text('Sessão ativa', key: _signedInKey)),
        signedOutChild: const Scaffold(
          body: Text('Introduzir código SMS', key: _signedOutKey),
        ),
        loadingChild: const Scaffold(
          body: Text('A recuperar sessão', key: _loadingKey),
        ),
      ),
    ),
  );
}

class _ControlledAuthRepository extends FakeAuthRepository {
  _ControlledAuthRepository({AppUser? initialUser}) {
    setUser(initialUser);
    _controller = StreamController<AppUser?>.broadcast(
      sync: true,
      onCancel: () => cancelledSubscriptions++,
    );
  }

  late final StreamController<AppUser?> _controller;
  int streamReads = 0;
  int cancelledSubscriptions = 0;
  int signOutCalls = 0;

  bool get hasListener => _controller.hasListener;

  @override
  Stream<AppUser?> get onAuthStateChanged {
    streamReads++;
    // A fresh derived stream makes retry/resubscription observable while
    // keeping every event under the test's control.
    return _controller.stream.map((user) => user);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await super.signOut();
  }

  void emitUser(AppUser? user) {
    setUser(user);
    _controller.add(user);
  }

  void emitError(Object error) {
    _controller.addError(error, StackTrace.current);
  }

  Future<void> close() => _controller.close();
}

class _SessionCounter extends StatefulWidget {
  const _SessionCounter({required this.onMounted});

  final VoidCallback onMounted;

  @override
  State<_SessionCounter> createState() => _SessionCounterState();
}

class _SessionCounterState extends State<_SessionCounter> {
  var _count = 0;

  @override
  void initState() {
    super.initState();
    widget.onMounted();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('Estado da sessão: $_count'),
        TextButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Incrementar'),
        ),
      ],
    ),
  );
}
