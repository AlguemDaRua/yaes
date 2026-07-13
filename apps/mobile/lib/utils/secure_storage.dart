import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Preferences {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveNumber(String number) async {
    await _storage.write(key: 'number', value: number);
  }

  static Future<String?> getNumber() async {
    return _storage.read(key: 'number');
  }

  static Future<void> removeNumber() async {
    await _storage.delete(key: 'number');
  }

  static Future<void> saveType(String type) async {
    await _storage.write(key: 'type', value: type);
  }

  static Future<String?> getType() async {
    return _storage.read(key: 'type');
  }

  static Future<void> removeType() async {
    await _storage.delete(key: 'type');
  }
}
