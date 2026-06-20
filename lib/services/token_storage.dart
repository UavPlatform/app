import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'jwt_refresh_token';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await Future.wait([
      _prefs.setString(_tokenKey, token),
      _prefs.setString(_refreshTokenKey, refreshToken),
    ]);
  }

  String? getToken() => _prefs.getString(_tokenKey);
  String? getRefreshToken() => _prefs.getString(_refreshTokenKey);

  bool get hasToken => getToken() != null && getRefreshToken() != null;

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_tokenKey),
      _prefs.remove(_refreshTokenKey),
    ]);
  }
}
