class ApiConfig {
  /// 内置默认后端地址（P1-5 缺省策略）：
  /// 新装首启本地未持久化 serverUrl 时，REST/WS 一律回落到该地址，
  /// 保证「新装首启请求可达默认环境」，不再出现 baseUrl 空串导致全部请求失败。
  static const String defaultBaseUrl = 'http://192.168.172.21:8081';

  /// 解析生效的 baseUrl：本地配置优先，缺省回落内置默认地址。
  static String resolveBaseUrl(String? storedUrl) {
    final trimmed = storedUrl?.trim() ?? '';
    if (trimmed.isEmpty) return defaultBaseUrl;
    return trimmed;
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
