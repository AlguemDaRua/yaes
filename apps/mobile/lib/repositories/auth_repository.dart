abstract class IAuthRepository {
  /// Stream of the current user status
  Stream<AppUser?> get onAuthStateChanged;

  /// Current user object
  AppUser? get currentUser;

  /// Step 1: Send SMS code
  Future<void> sendSmsCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onFailed,
  });

  /// Step 2: Verify SMS code and sign in
  Future<String?> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  });

  /// Get user type (passenger/driver)
  Future<String> getUserType(String uid);

  /// Logout
  Future<void> signOut();
}

/// A generic user model to decouple the UI from Firebase's User class
class AppUser {
  final String uid;
  final String? phoneNumber;
  final String? email;

  AppUser({required this.uid, this.phoneNumber, this.email});
}
