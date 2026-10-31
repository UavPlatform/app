class ApiConfig {
  /// 内置默认后端地址（P1-5 缺省策略）：
  /// 新装首启本地未持久化 serverUrl 时，REST/WS 一律回落到该地址，
  /// 保证「新装首启请求可达默认环境」，不再出现 baseUrl 空串导致全部请求失败。
  static const String defaultBaseUrl = 'http://192.168.172.21:8081';

  /// 网关根地址（展示、WebSocket `/ws/...`）：本地配置优先，缺省回落内置默认。
  static String resolveBaseUrl(String? storedUrl) {
    final trimmed = storedUrl?.trim() ?? '';
    final raw = trimmed.isEmpty ? defaultBaseUrl : trimmed;
    return _ensureTrailingSlash(raw);
  }

  /// REST（Dio）基址：经 Caddy 等网关时 API 挂在 `/api`（见 backend/deploy/Caddyfile），
  /// 直连 Spring（典型 :8081）则不加前缀。
  static String resolveHttpBaseUrl(String? storedUrl) {
    final origin = resolveBaseUrl(storedUrl);
    final uri = Uri.tryParse(origin);
    if (uri == null) return origin;

    var path = uri.path;
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    if (path == '/api' || path.endsWith('/api')) {
      return _ensureTrailingSlash(origin);
    }
    // 直连 Spring Boot：常见本地/IT 端口（含 tools/it 默认 8082）不加 /api 前缀。
    if ((path.isEmpty || path == '/') &&
        (uri.port == 8081 || uri.port == 8080 || uri.port == 8082)) {
      return _ensureTrailingSlash(origin);
    }
    if (path.isEmpty || path == '/') {
      return _ensureTrailingSlash(uri.replace(path: '/api').toString());
    }
    return _ensureTrailingSlash(origin);
  }

  static String _ensureTrailingSlash(String url) {
    return url.endsWith('/') ? url : '$url/';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
