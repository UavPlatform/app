import 'result_model.dart';

class AmapConfig {
  final String key;
  final String securityKey;

  AmapConfig({required this.key, required this.securityKey});

  factory AmapConfig.fromJson(Map<String, dynamic> json) {
    return AmapConfig(
      key: json['key'] as String,
      securityKey: json['securityKey'] as String,//实则安卓的key没有这个字段，不想改后端了，暂且这样
    );
  }

  static Result<AmapConfig> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => AmapConfig.fromJson(data));
  }
}
