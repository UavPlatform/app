class ApiConfig {
  static const String baseUrl = 'http://120.77.170.101:8888/api/';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Token 过期提前刷新时间
  static const Duration tokenRefreshAhead = Duration(minutes: 5);
}
