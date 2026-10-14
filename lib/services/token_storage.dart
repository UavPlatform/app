import 'package:shared_preferences/shared_preferences.dart';

/// Token 刷新结果三态：
/// - refreshed：拿到新 accessToken 并已持久化；
/// - rejected：服务端可达但明确拒绝刷新（refreshToken 失效/缺失）→ 会话彻底失效；
/// - unreachable：网络性失败（连接失败/超时/5xx）→ 维持现状稍后重试。
enum TokenRefreshOutcome { refreshed, rejected, unreachable }

class TokenStorage {
  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'jwt_refresh_token';
  static const _serverUrlKey = 'server_url';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  String? getServerUrl() {
    final url = _prefs.getString(_serverUrlKey);
    return normalizeHttpServerUrl(url);
  }

  Future<void> saveServerUrl(String url) =>
      _prefs.setString(_serverUrlKey, normalizeHttpServerUrl(url) ?? '');

  static String? normalizeHttpServerUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return trimmed;

    // 用户常只填 host:port（如 192.168.1.1:8080）；Dart Uri 无法解析无 scheme 的 host:port，
    // Dio baseUrl 会无效并表现为「网络请求失败」。
    final withScheme = _ensureHttpScheme(trimmed);

    final uri = Uri.tryParse(withScheme);
    if (uri == null) return withScheme;

    if (uri.scheme == 'ws' || uri.scheme == 'wss') {
      return uri
          .replace(scheme: uri.scheme == 'wss' ? 'https' : 'http')
          .toString();
    }
    return withScheme;
  }

  static String _ensureHttpScheme(String trimmed) {
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('ws://') ||
        lower.startsWith('wss://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

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
