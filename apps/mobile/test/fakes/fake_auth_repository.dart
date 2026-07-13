import 'package:limousineexecutive/repositories/auth_repository.dart';

class FakeAuthRepository implements IAuthRepository {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get onAuthStateChanged => Stream.value(_user);

  @override
  Future<void> sendSmsCode({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onFailed,
  }) async {
    onCodeSent('fake-v-id', 1234);
  }

  @override
  Future<String?> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    _user = AppUser(uid: 'fake-uid', phoneNumber: '+258840000000');
    return _user!.uid;
  }

  @override
  Future<String> getUserType(String uid) async => 'passenger';

  @override
  Future<void> signOut() async {
    _user = null;
  }

  void setUser(AppUser? user) {
    _user = user;
  }
}
