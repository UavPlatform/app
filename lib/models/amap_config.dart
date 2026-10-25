import '../api/generated/openapi_models.dart';
import 'result_model.dart';

/// 原生端地图配置：只有 Android SDK key，securityKey 留在服务端（Web 走高德安全代理）。
class AmapConfig {
  final String key;

  AmapConfig({required this.key});

  factory AmapConfig.fromJson(Map<String, dynamic> json) {
    final c = ApiMapConfigVO.fromJson(json);
    return AmapConfig(key: c.key);
  }

  static Result<AmapConfig> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => AmapConfig.fromJson(data));
  }
}
