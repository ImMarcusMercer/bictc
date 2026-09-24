import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class DeviceLocalStore implements LocalStore {
  // Construct lazily so unsupported storage becomes a recoverable feature error.
  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();
  @override
  Future<String?> read(String key) => _store.getString(key);
  @override
  Future<void> write(String key, String value) => _store.setString(key, value);
}

class MemoryLocalStore implements LocalStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
