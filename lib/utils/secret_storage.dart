import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tokens and API keys live in the OS keystore. SharedPreferences is plain
/// XML on disk and every key in it goes into the `.memex` backup.
class SecretStorage {
  static const _storage = FlutterSecureStorage();

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> deleteAll() => _storage.deleteAll();

  /// Reads [key], first moving a plain value left in SharedPreferences by an
  /// older version (or by a restored backup) into the keystore.
  static Future<String?> readMigrating(
      SharedPreferences prefs, String key) async {
    final legacy = prefs.getString(key);
    if (legacy != null) {
      await write(key, legacy);
      await prefs.remove(key);
      return legacy;
    }
    return read(key);
  }
}
