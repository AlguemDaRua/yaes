import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:limousineexecutive/utils/secure_storage.dart';
import 'package:limousineexecutive/utils/user_data.dart';
import 'package:limousineexecutive/services/session_role_service.dart';
import 'auth_repository.dart';

const bool _useEmulators = bool.fromEnvironment('USE_EMULATORS');

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Native Firebase persists credentials itself. Web must explicitly use
  /// local persistence; resolve the SDK's initial state before mounting routes.
  static Future<void> initializeSession() async {
    final auth = FirebaseAuth.instance;
    if (kIsWeb) await auth.setPersistence(Persistence.LOCAL);
    try {
      final user = await auth.authStateChanges().first.timeout(
        const Duration(seconds: 8),
      );
      debugPrint(
        user == null
            ? '[SESSION][STARTUP] Firebase não devolveu uma sessão guardada.'
            : '[SESSION][STARTUP] Sessão guardada recuperada pelo Firebase.',
      );
    } catch (_) {
      // AuthSessionGate keeps observing the SDK and shows a retry for errors.
      debugPrint(
        '[SESSION][STARTUP] Restauração pendente; o login não é forçado.',
      );
    }
  }

  FirebaseAuthRepository() {
    // Só no emulador: desliga reCAPTCHA/verificação de app para os números de
    // teste terem código fixo determinístico. Nunca em produção.
    if (_useEmulators) {
      _auth
          .setSettings(appVerificationDisabledForTesting: true)
          .catchError((_) {});
    }
  }

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user != null
        ? AppUser(
            uid: user.uid,
            phoneNumber: user.phoneNumber,
            email: user.email,
          )
        : null;
  }

  @override
  Stream<AppUser?> get onAuthStateChanged {
    return _auth.authStateChanges().map((user) {
      return user != null
          ? AppUser(
              uid: user.uid,
              phoneNumber: user.phoneNumber,
              email: user.email,
            )
          : null;
    });
  }

  @override
  Future<void> sendSmsCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          final user = result.user;
          if (user != null) {
            await _ensureProfileExists(user.uid, user.phoneNumber ?? '');
          }
        } on FirebaseAuthException catch (error) {
          onFailed(error.message ?? 'Não foi possível verificar o número.');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? 'Erro na verificação');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<String?> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('[SESSION][LOGIN] OTP confirmado pelo Firebase.');
      final uid = userCredential.user?.uid;

      if (uid != null) {
        await _ensureProfileExists(uid, userCredential.user!.phoneNumber ?? '');
      }

      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw Exception('Código inválido. Tente novamente.');
      } else if (e.code == 'session-expired') {
        throw Exception('O código expirou. Reenvie um novo código.');
      } else {
        throw Exception(e.message ?? 'Erro de autenticação.');
      }
    }
  }

  @override
  Future<String> getUserType(String uid) async {
    final snapshot = await _db.child('users/$uid/type').get();
    if (snapshot.exists) {
      return snapshot.value as String;
    }
    return 'passenger';
  }

  Future<void> _ensureProfileExists(String uid, String phone) async {
    // Best-effort com timeout: o login NUNCA pode ficar preso à espera desta
    // escrita (rede fraca, escrita em fila, etc.). Se falhar, o perfil é criado
    // no próximo arranque; a escrita fica em fila e o SDK reenvia-a.
    try {
      final snapshot = await _db
          .child('users/$uid')
          .get()
          .timeout(const Duration(seconds: 6));
      if (!snapshot.exists) {
        await _db
            .child('users/$uid')
            .set({
              'phone': phone,
              'name': '',
              'email': '',
              'rating': null,
              'ratingCount': 0,
              'photoUrl': '',
              'type': 'passenger',
              'createdAt': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      debugPrint('ensureProfileExists falhou (ignorado): $e');
    }
  }

  @override
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    // Only this explicit action clears Firebase's persisted authentication.
    // Network or optional metadata failures must not interrupt sign-out.
    if (!kIsWeb && uid != null) {
      await _cleanUp(() => _db.child('users/$uid/fcmToken').remove());
    }
    debugPrint(
      '[SESSION][LOGOUT] Saída solicitada explicitamente pelo utilizador.',
    );
    await _auth.signOut();
    UserData.phoneNumber = '';
    UserData.name = '';
    UserData.email = '';
    UserData.rating = null;
    await Future.wait([
      _cleanUp(() => Preferences.removeNumber()),
      _cleanUp(() => Preferences.removeType()),
      if (uid != null)
        _cleanUp(() => SharedPreferencesSessionRoleCache().remove(uid)),
      if (!kIsWeb) ...[
        _cleanUp(() => FirebaseMessaging.instance.deleteToken()),
      ],
    ]);
  }

  Future<void> _cleanUp(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 2));
    } catch (_) {
      debugPrint('[SESSION] Limpeza de dados auxiliares pendente.');
    }
  }
}
