import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _themeModeKey = 'theme_mode';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveUserData(String userDataJson) async {
    await _storage.write(key: _userDataKey, value: userDataJson);
  }

  Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(key: _themeModeKey, value: themeMode);
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async => await _storage.read(key: _refreshTokenKey);
  Future<String?> getUserData() async => await _storage.read(key: _userDataKey);
  Future<String?> getThemeMode() async => await _storage.read(key: _themeModeKey);

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
