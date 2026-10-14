import '../api/generated/openapi_models.dart';
import 'result_model.dart';

class AmapConfig {
  final String key;
  final String securityKey;

  AmapConfig({required this.key, required this.securityKey});

  factory AmapConfig.fromJson(Map<String, dynamic> json) {
    final c = ApiAmapConfigVO.fromJson(json);
    return AmapConfig(
      key: c.key as String,
      // Android SDK credentials do not require the JS API security key.
      securityKey: c.securityKey ?? '',
    );
  }

  static Result<AmapConfig> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => AmapConfig.fromJson(data));
  }
}
