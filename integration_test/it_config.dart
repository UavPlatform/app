/// 真实后端 IT 配置（`--dart-define`）。
///
/// 例：
/// ```
/// flutter test integration_test \\
///   --dart-define=IT_BASE_URL=http://127.0.0.1:8082 \\
///   --dart-define=SKIP_TRTC=true
/// ```
class ItConfig {
  static const baseUrl = String.fromEnvironment(
    'IT_BASE_URL',
    defaultValue: 'http://127.0.0.1:8082',
  );
  static const password = String.fromEnvironment(
    'IT_PASSWORD',
    defaultValue: 'It@123456',
  );
  static const adminUser = 'it-admin';
  static const pilotUser = 'it-pilot';
  static const customerUser = 'it-customer';
  static const droneSerial = 'IT-DRONE-001';

  static bool get hasBaseUrl => baseUrl.trim().isNotEmpty;
}
