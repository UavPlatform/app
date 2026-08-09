class ApiConfig {
  // 本地联调：本机局域网 IP（后端无 /api/ 前缀，8081 端口）；联调完记得改回线上地址
  static const String baseUrl = 'http://192.168.1.4:8081/';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Token 过期提前刷新时间
  static const Duration tokenRefreshAhead = Duration(minutes: 5);
}
