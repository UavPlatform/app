import 'result_model.dart';
import 'create_task_request.dart';

/// 计费明细项（起步价/里程费/重量费/夜间附加费，0 元项后端已省略）
class PriceDetailItem {
  final String name;
  final double amount;

  PriceDetailItem({required this.name, required this.amount});

  factory PriceDetailItem.fromJson(Map<String, dynamic> json) {
    return PriceDetailItem(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// 平台参考价明细（total = items 之和）
class PriceDetail {
  final double? total;
  final List<PriceDetailItem> items;
  final double? distanceKm;
  final double? weightKg;
  final bool? isNight;
  final bool? needManualQuote;

  PriceDetail({
    this.total,
    this.items = const [],
    this.distanceKm,
    this.weightKg,
    this.isNight,
    this.needManualQuote,
  });

  factory PriceDetail.fromJson(Map<String, dynamic> json) {
    return PriceDetail(
      total: (json['total'] as num?)?.toDouble(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => PriceDetailItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      isNight: json['isNight'] as bool?,
      needManualQuote: json['needManualQuote'] as bool?,
    );
  }

  static Result<PriceDetail> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => PriceDetail.fromJson(data));
  }
}

/// 参考价预估请求（与创建任务同口径）
class PriceEstimateRequest {
  final String? taskType;
  final List<WaypointRequest> waypoints;
  final double? weight;
  final String? taskTime;

  PriceEstimateRequest({
    this.taskType,
    required this.waypoints,
    this.weight,
    this.taskTime,
  });

  Map<String, dynamic> toJson() => {
        if (taskType != null) 'taskType': taskType,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        if (weight != null) 'weight': weight,
        if (taskTime != null) 'taskTime': taskTime,
      };
}
