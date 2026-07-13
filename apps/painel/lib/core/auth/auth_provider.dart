import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_user.dart';

class _MockCredentials {
  const _MockCredentials({
    required this.email,
    required this.password,
    required this.user,
  });

  final String email;
  final String password;
  final AuthUser user;
}

const List<_MockCredentials> _mockUsers = <_MockCredentials>[
  _MockCredentials(
    email: 'admin@ya.co.mz',
    password: 'admin123',
    user: AuthUser(
      uid: 'usr-admin-001',
      email: 'admin@ya.co.mz',
      name: 'Amina Mussa',
      role: UserRole.admin,
    ),
  ),
  _MockCredentials(
    email: 'partner@maputoexec.co.mz',
    password: 'partner123',
    user: AuthUser(
      uid: 'usr-partner-001',
      email: 'partner@maputoexec.co.mz',
      name: 'Maputo Executive',
      role: UserRole.partner,
      partnerId: 'ptr-maputo-exec',
    ),
  ),
  _MockCredentials(
    email: 'support@ya.co.mz',
    password: 'support123',
    user: AuthUser(
      uid: 'usr-support-001',
      email: 'support@ya.co.mz',
      name: 'Antonio Massango',
      role: UserRole.support,
    ),
  ),
];

class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier();

  AuthUser? _user;
  bool _usesFirebase = false;
  bool _resolvingFirebaseUser = false;
  bool _needsEmailVerification = false;
  String? _pendingEmail;
  String? _pendingVerificationId;
  String? _lastError;
  firebase_auth.ConfirmationResult? _webConfirmationResult;
  StreamSubscription<firebase_auth.User?>? _firebaseSub;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get usesFirebase => _usesFirebase;
  bool get isResolving => _resolvingFirebaseUser;
  bool get needsEmailVerification => _needsEmailVerification;
  String? get pendingEmail => _pendingEmail;
  String? get lastError => _lastError;

  Future<void> useFirebaseAuth() async {
    if (_usesFirebase) return;

    _usesFirebase = true;
    _user = null;
    _lastError = null;
    _resolvingFirebaseUser = true;
    notifyListeners();

    _firebaseSub =
        firebase_auth.FirebaseAuth.instance.authStateChanges().listen(
      (firebase_auth.User? fbUser) {
        unawaited(_onFirebaseAuthChanged(fbUser));
      },
    );
  }

  void bootstrapAdminForDev() {
    if (_usesFirebase) return;
    _user = _mockUsers.first.user;
    notifyListeners();
  }

  @visibleForTesting
  void setRoleForTest(UserRole role) {
    _usesFirebase = false;
    _resolvingFirebaseUser = false;
    _lastError = null;
    _user = _mockUsers.firstWhere((c) => c.user.role == role).user;
    notifyListeners();
  }

  Future<AuthUser?> signIn(String email, String password) async {
    if (_usesFirebase) return null;

    final String normalized = email.trim().toLowerCase();
    final _MockCredentials? match =
        _mockUsers.cast<_MockCredentials?>().firstWhere(
              (c) => c!.email == normalized && c.password == password,
              orElse: () => null,
            );
    if (match == null) return null;
    _user = match.user;
    notifyListeners();
    return match.user;
  }

  /// Login com email + password contra Firebase Auth (modo painel).
  /// Devolve `true` se autenticado e profile resolvido. Erros postos em
  /// [lastError]. Se email não verificado, [needsEmailVerification] fica
  /// `true` e o user fica em estado "pendente" (não signed-out).
  Future<bool> signInWithEmail(String email, String password) async {
    if (!_usesFirebase) {
      // Em modo mock, delega para [signIn].
      final AuthUser? u = await signIn(email, password);
      return u != null;
    }

    final String normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.isEmpty) {
      _lastError = 'Introduz email e password.';
      notifyListeners();
      return false;
    }

    try {
      _lastError = null;
      final firebase_auth.UserCredential credential =
          await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      return _resolveSignedInCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastError = _messageForFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (_) {
      _lastError = 'Nao foi possivel entrar.';
      notifyListeners();
      return false;
    }
  }

  /// Envia email com link de reset de password.
  Future<bool> sendPasswordReset(String email) async {
    if (!_usesFirebase) {
      _lastError = null;
      notifyListeners();
      return true;
    }
    final String normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      _lastError = 'Introduz o email.';
      notifyListeners();
      return false;
    }
    try {
      _lastError = null;
      await firebase_auth.FirebaseAuth.instance
          .sendPasswordResetEmail(email: normalized);
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastError = _messageForFirebaseAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Reenviar email de verificação para o user actual (não verificado).
  Future<bool> sendEmailVerification() async {
    if (!_usesFirebase) return true;
    final firebase_auth.User? fbUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return false;
    try {
      await fbUser.sendEmailVerification();
      _lastError = null;
      notifyListeners();
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastError = _messageForFirebaseAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Refresca o user actual (útil depois do user clicar no link de
  /// verificação via email). Se ficou verificado, resolve o app user.
  Future<bool> refreshUser() async {
    if (!_usesFirebase) return _user != null;
    final firebase_auth.User? fbUser =
        firebase_auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return false;
    try {
      await fbUser.reload();
      final firebase_auth.User? refreshed =
          firebase_auth.FirebaseAuth.instance.currentUser;
      if (refreshed == null) return false;
      await _onFirebaseAuthChanged(refreshed);
      return _user != null;
    } catch (_) {
      return false;
    }
  }

  /// Mantido por retrocompatibilidade (era OTP). Não usado em produção.
  Future<bool> sendOtp(String phone) async {
    if (!_usesFirebase) return false;

    final String normalized = _normalizeMozambiquePhone(phone);
    if (!_isValidMozambiquePhone(normalized)) {
      _lastError = 'Introduz um numero valido com prefixo +258.';
      notifyListeners();
      return false;
    }

    try {
      _lastError = null;
      if (kIsWeb) {
        _webConfirmationResult = await firebase_auth.FirebaseAuth.instance
            .signInWithPhoneNumber(normalized);
        return true;
      }

      final Completer<bool> completer = Completer<bool>();
      await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) {
          unawaited(_completeCredentialSignIn(credential));
          if (!completer.isCompleted) completer.complete(true);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _lastError = e.message ?? 'Nao foi possivel enviar o codigo.';
          if (!completer.isCompleted) completer.complete(false);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _pendingVerificationId = verificationId;
          if (!completer.isCompleted) completer.complete(true);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _pendingVerificationId = verificationId;
        },
      );
      return completer.future;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastError = e.message ?? 'Nao foi possivel enviar o codigo.';
      notifyListeners();
      return false;
    } catch (_) {
      _lastError = 'Nao foi possivel enviar o codigo.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    if (!_usesFirebase) return false;

    final String trimmed = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      _lastError = 'Introduz o codigo de 6 digitos.';
      notifyListeners();
      return false;
    }

    try {
      _lastError = null;
      if (kIsWeb) {
        final firebase_auth.ConfirmationResult? confirmation =
            _webConfirmationResult;
        if (confirmation == null) {
          _lastError = 'Envia um codigo antes de verificar.';
          notifyListeners();
          return false;
        }
        final firebase_auth.UserCredential credential =
            await confirmation.confirm(trimmed);
        return _resolveSignedInCredential(credential);
      }

      final String? verificationId = _pendingVerificationId;
      if (verificationId == null) {
        _lastError = 'Envia um codigo antes de verificar.';
        notifyListeners();
        return false;
      }
      final firebase_auth.PhoneAuthCredential credential =
          firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: trimmed,
      );
      return _completeCredentialSignIn(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _lastError = _messageForFirebaseAuthError(e);
      notifyListeners();
      return false;
    } catch (_) {
      _lastError = 'Nao foi possivel verificar o codigo.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _pendingVerificationId = null;
    _webConfirmationResult = null;
    _lastError = null;
    _needsEmailVerification = false;
    _pendingEmail = null;
    if (_usesFirebase) {
      await firebase_auth.FirebaseAuth.instance.signOut();
    }
    _user = null;
    _resolvingFirebaseUser = false;
    notifyListeners();
  }

  Future<void> _onFirebaseAuthChanged(firebase_auth.User? fbUser) async {
    _resolvingFirebaseUser = true;
    notifyListeners();

    if (fbUser == null) {
      _user = null;
      _needsEmailVerification = false;
      _pendingEmail = null;
      _resolvingFirebaseUser = false;
      notifyListeners();
      return;
    }

    // Login por email/password requer email verificado.
    final bool isEmailLogin = fbUser.email != null &&
        fbUser.providerData.any((p) => p.providerId == 'password');
    if (isEmailLogin && !fbUser.emailVerified) {
      _user = null;
      _needsEmailVerification = true;
      _pendingEmail = fbUser.email;
      _lastError = 'Confirma o email antes de entrar.';
      _resolvingFirebaseUser = false;
      notifyListeners();
      return;
    }

    final AuthUser? resolved = await _resolveAppUser(fbUser);
    if (resolved == null) {
      _user = null;
      _needsEmailVerification = false;
      _pendingEmail = null;
      _lastError =
          'Esta conta nao tem acesso ao painel. Contacta o administrador.';
      _resolvingFirebaseUser = false;
      notifyListeners();
      await firebase_auth.FirebaseAuth.instance.signOut();
      return;
    }

    _user = resolved;
    _needsEmailVerification = false;
    _pendingEmail = null;
    _lastError = null;
    _resolvingFirebaseUser = false;
    notifyListeners();
  }

  Future<bool> _completeCredentialSignIn(
    firebase_auth.PhoneAuthCredential credential,
  ) async {
    final firebase_auth.UserCredential userCredential =
        await firebase_auth.FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    return _resolveSignedInCredential(userCredential);
  }

  Future<bool> _resolveSignedInCredential(
    firebase_auth.UserCredential credential,
  ) async {
    final firebase_auth.User? fbUser = credential.user;
    if (fbUser == null) return false;

    _resolvingFirebaseUser = true;
    notifyListeners();

    // Login por email/password requer email verificado.
    final bool isEmailLogin = fbUser.email != null &&
        fbUser.providerData.any((p) => p.providerId == 'password');
    if (isEmailLogin && !fbUser.emailVerified) {
      _user = null;
      _needsEmailVerification = true;
      _pendingEmail = fbUser.email;
      _lastError = 'Confirma o email antes de entrar.';
      _resolvingFirebaseUser = false;
      notifyListeners();
      return false;
    }

    final AuthUser? resolved = await _resolveAppUser(fbUser);
    _resolvingFirebaseUser = false;

    if (resolved == null) {
      _user = null;
      _needsEmailVerification = false;
      _pendingEmail = null;
      _lastError =
          'Esta conta nao tem acesso ao painel. Contacta o administrador.';
      notifyListeners();
      await firebase_auth.FirebaseAuth.instance.signOut();
      return false;
    }

    _user = resolved;
    _needsEmailVerification = false;
    _pendingEmail = null;
    _lastError = null;
    notifyListeners();
    return true;
  }

  Future<AuthUser?> _resolveAppUser(firebase_auth.User fbUser) async {
    final DatabaseReference db = FirebaseDatabase.instance.ref();
    final String uid = fbUser.uid;

    final DataSnapshot adminSnap = await db.child('admins/$uid').get();
    final DataSnapshot profileSnap = await db.child('users/$uid').get();
    final Map<String, dynamic> profile = _snapshotMap(profileSnap);

    if (adminSnap.exists && adminSnap.value == true) {
      return AuthUser(
        uid: uid,
        email: _stringField(profile, 'email') ?? fbUser.email ?? '',
        name: _displayName(profile, fbUser, fallback: 'Admin'),
        role: UserRole.admin,
        avatarUrl: _avatarUrl(profile),
      );
    }

    if (!profileSnap.exists) return null;

    final String type = _stringField(profile, 'type') ?? 'passenger';
    final UserRole? role = switch (type) {
      'admin' => UserRole.admin,
      'partner_owner' || 'partner_staff' => UserRole.partner,
      'support' => UserRole.support,
      _ => null,
    };
    if (role == null) return null;

    return AuthUser(
      uid: uid,
      email: _stringField(profile, 'email') ?? fbUser.email ?? '',
      name: _displayName(profile, fbUser, fallback: 'Sem nome'),
      role: role,
      partnerId: _stringField(profile, 'partnerId'),
      avatarUrl: _avatarUrl(profile),
    );
  }

  Map<String, dynamic> _snapshotMap(DataSnapshot snapshot) {
    final Object? value = snapshot.value;
    if (!snapshot.exists || value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(value);
  }

  String _displayName(
    Map<String, dynamic> profile,
    firebase_auth.User fbUser, {
    required String fallback,
  }) {
    final String? name = _stringField(profile, 'name') ?? fbUser.displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return fbUser.phoneNumber ?? fallback;
  }

  String? _avatarUrl(Map<String, dynamic> profile) {
    return _stringField(profile, 'avatarUrl') ??
        _stringField(profile, 'photoUrl');
  }

  String? _stringField(Map<String, dynamic> map, String key) {
    final Object? value = map[key];
    return value is String ? value : null;
  }

  String _normalizeMozambiquePhone(String raw) {
    final String compact = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (compact.startsWith('+')) return compact;
    if (compact.startsWith('258')) return '+$compact';
    if (compact.length == 9 && compact.startsWith('8')) return '+258$compact';
    return compact;
  }

  bool _isValidMozambiquePhone(String phone) {
    return RegExp(r'^\+258\d{9}$').hasMatch(phone);
  }

  String _messageForFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-verification-code' => 'Codigo invalido. Tenta novamente.',
      'session-expired' => 'O codigo expirou. Envia um novo codigo.',
      _ => e.message ?? 'Nao foi possivel autenticar.',
    };
  }

  @override
  void dispose() {
    unawaited(_firebaseSub?.cancel());
    super.dispose();
  }
}

final AuthChangeNotifier authNotifier = AuthChangeNotifier()
  ..bootstrapAdminForDev();

final NotifierProvider<AuthStateNotifier, AuthUser?> authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthUser?>(AuthStateNotifier.new);

class AuthStateNotifier extends Notifier<AuthUser?> {
  @override
  AuthUser? build() {
    authNotifier.addListener(_onChange);
    ref.onDispose(() => authNotifier.removeListener(_onChange));
    return authNotifier.user;
  }

  void _onChange() {
    state = authNotifier.user;
  }

  Future<bool> signIn(String email, String password) async {
    if (authNotifier.usesFirebase) {
      return authNotifier.signInWithEmail(email, password);
    }
    final AuthUser? u = await authNotifier.signIn(email, password);
    return u != null;
  }

  Future<bool> signInWithEmail(String email, String password) =>
      authNotifier.signInWithEmail(email, password);

  Future<bool> sendPasswordReset(String email) =>
      authNotifier.sendPasswordReset(email);

  Future<bool> sendEmailVerification() => authNotifier.sendEmailVerification();

  Future<bool> refreshUser() => authNotifier.refreshUser();

  Future<bool> sendOtp(String phone) => authNotifier.sendOtp(phone);

  Future<bool> verifyOtp(String code) => authNotifier.verifyOtp(code);

  Future<void> signOut() => authNotifier.signOut();
}
