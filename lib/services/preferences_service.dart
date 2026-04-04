import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesService {
  static const _storage = FlutterSecureStorage();

  static const _keyUserName = 'user_name';
  static const _keyUserHostel = 'user_hostel';

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  static Future<void> setUserName(String name) async {
    await _storage.write(key: _keyUserName, value: name);
  }

  static Future<String?> getUserHostel() async {
    return await _storage.read(key: _keyUserHostel);
  }

  static Future<void> setUserHostel(String hostel) async {
    await _storage.write(key: _keyUserHostel, value: hostel);
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserHostel);
  }
}
