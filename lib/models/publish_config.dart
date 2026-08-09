import 'result_model.dart';

/// 发布页配置：重量输入是否展示、协商价下限
class PublishConfig {
  final List<String> weightTypes;
  final double? minNegotiatedRate;

  PublishConfig({this.weightTypes = const [], this.minNegotiatedRate});

  factory PublishConfig.fromJson(Map<String, dynamic> json) {
    return PublishConfig(
      weightTypes: (json['weightTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      minNegotiatedRate: (json['minNegotiatedRate'] as num?)?.toDouble(),
    );
  }

  /// 该任务类型是否参与重量计费（决定发布页是否显示重量输入）
  bool isWeightType(String type) => weightTypes.contains(type);

  static Result<PublishConfig> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => PublishConfig.fromJson(data));
  }
}
