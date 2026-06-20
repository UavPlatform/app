class ApiConfig {
  static const String baseUrl = 'http://10.233.199.21:8081';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Token 过期提前刷新时间
  static const Duration tokenRefreshAhead = Duration(minutes: 5);
}
