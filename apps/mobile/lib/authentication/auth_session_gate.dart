import 'dart:async';

import 'package:flutter/material.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';

/// Firebase owns the persisted credentials. Keep listening after startup so a
/// delayed native restore or automatic SMS sign-in also leaves the login flow.
class AuthSessionGate extends StatefulWidget {
  const AuthSessionGate({
    super.key,
    required this.authRepository,
    required this.signedInChild,
    required this.signedOutChild,
    this.loadingChild,
    this.restoreTimeout = const Duration(seconds: 8),
    this.initialNullDelay = const Duration(milliseconds: 500),
  });

  final IAuthRepository authRepository;
  final Widget signedInChild;
  final Widget signedOutChild;
  final Widget? loadingChild;
  final Duration restoreTimeout;
  final Duration initialNullDelay;

  @override
  State<AuthSessionGate> createState() => _AuthSessionGateState();
}

class _AuthSessionGateState extends State<AuthSessionGate> {
  StreamSubscription<AppUser?>? _subscription;
  Timer? _restoreTimer;
  Timer? _initialNullTimer;
  AppUser? _user;
  bool _resolved = false;
  bool _receivedEvent = false;
  bool _restoreFailed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant AuthSessionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository) _listen();
  }

  void _listen() {
    final generation = ++_generation;
    _subscription?.cancel();
    _restoreTimer?.cancel();
    _initialNullTimer?.cancel();
    _initialNullTimer = null;
    _user = widget.authRepository.currentUser;
    _resolved = _user != null;
    _receivedEvent = false;
    _restoreFailed = false;

    if (!_resolved) {
      _restoreTimer = Timer(widget.restoreTimeout, () {
        if (!mounted || generation != _generation || _receivedEvent) return;
        final restoredUser = widget.authRepository.currentUser;
        setState(() {
          _user = restoredUser;
          _resolved = restoredUser != null;
          _restoreFailed = restoredUser == null;
        });
      });
    }

    _subscription = widget.authRepository.onAuthStateChanged.listen(
      (user) {
        if (!mounted || generation != _generation) return;
        _restoreTimer?.cancel();
        _receivedEvent = true;
        if (user == null && !_resolved) {
          // The SDK initially yields currentUser, which can still be null.
          // Preserve the subscription instead of permanently choosing login.
          _initialNullTimer ??= Timer(widget.initialNullDelay, () {
            if (!mounted || generation != _generation) return;
            // Re-read the SDK instead of treating the early null snapshot as
            // proof that the persisted session was lost.
            final restoredUser = widget.authRepository.currentUser;
            setState(() {
              _user = restoredUser;
              _resolved = true;
              _restoreFailed = false;
            });
          });
          return;
        }
        _initialNullTimer?.cancel();
        _initialNullTimer = null;
        setState(() {
          _user = user ?? widget.authRepository.currentUser;
          _resolved = true;
          _restoreFailed = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted || generation != _generation) return;
        _restoreTimer?.cancel();
        _initialNullTimer?.cancel();
        _initialNullTimer = null;
        debugPrint('[SESSION] Não foi possível confirmar a autenticação.');
        // A stream/network error is not a signed-out event.
        if (!_resolved && _user == null) {
          setState(() => _restoreFailed = true);
        }
      },
      onDone: () {
        if (!mounted || generation != _generation || _receivedEvent) return;
        _restoreTimer?.cancel();
        if (_user == null) setState(() => _restoreFailed = true);
      },
    );
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _restoreTimer?.cancel();
    _initialNullTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoreFailed) {
      return _SessionRestoreView(onRetry: () => setState(_listen));
    }
    if (!_resolved) return widget.loadingChild ?? const _SessionRestoreView();
    if (_user == null) {
      return KeyedSubtree(
        key: const ValueKey('signed-out'),
        child: widget.signedOutChild,
      );
    }
    return KeyedSubtree(
      key: ValueKey('session-${_user!.uid}'),
      child: widget.signedInChild,
    );
  }
}

class _SessionRestoreView extends StatelessWidget {
  const _SessionRestoreView({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRetry == null)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFFE5A400),
                      ),
                    )
                  else ...[
                    Text(
                      'Não foi possível recuperar a sessão',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verifica a ligação e tenta novamente.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A400),
                        foregroundColor: const Color(0xFF24262B),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
