import '../api/generated/openapi_models.dart';

/// 飞手应征记录（GET /task/{taskNum}/applications，ADR-0003 撮合列表）。
///
/// `quotedAmount` 是平台规则算出的系统报价，只读展示；
/// ADR-0003 红线：客户端不存在任何议价/调价入口。
class TaskApplicationVo {
  final int? applicationId;
  final String? taskNum;
  final int? riderId;
  final String? riderName;
  final int? aircraftModelId;
  final String? aircraftModelName;
  final String? modelCode;
  final double? maxPayloadKg;
  final double? quotedAmount;
  final String? appliedAt;
  final String? matchStatus;
  final String? status;

  const TaskApplicationVo({
    this.applicationId,
    this.taskNum,
    this.riderId,
    this.riderName,
    this.aircraftModelId,
    this.aircraftModelName,
    this.modelCode,
    this.maxPayloadKg,
    this.quotedAmount,
    this.appliedAt,
    this.matchStatus,
    this.status,
  });

  /// 字段直取契约类（ApiTaskApplicationVO）：契约重命名/删除字段时此处编译失败。
  factory TaskApplicationVo.fromApi(ApiTaskApplicationVO c) {
    return TaskApplicationVo(
      applicationId: c.applicationId,
      taskNum: c.taskNum,
      riderId: c.riderId,
      riderName: c.riderName,
      aircraftModelId: c.aircraftModelId,
      aircraftModelName: c.aircraftModelName,
      modelCode: c.modelCode,
      maxPayloadKg: c.maxPayloadKg,
      quotedAmount: c.quotedAmount,
      appliedAt: c.appliedAt,
      matchStatus: c.matchStatus,
      status: c.status,
    );
  }

  factory TaskApplicationVo.fromJson(Map<String, dynamic> json) =>
      TaskApplicationVo.fromApi(ApiTaskApplicationVO.fromJson(json));

  /// 应征飞手展示名（服务端用户名兜底）。
  String get displayName =>
      (riderName != null && riderName!.isNotEmpty) ? riderName! : '飞手';

  /// 机型展示名：优先机型显示名（如 DJI FlyCart 30），退回型号编码（如 FC30）。
  String get aircraftLabel {
    if (aircraftModelName != null && aircraftModelName!.isNotEmpty) {
      return aircraftModelName!;
    }
    if (modelCode != null && modelCode!.isNotEmpty) return modelCode!;
    return '未知机型';
  }

  /// 载重展示（kg），无机型参数时返回空串。
  String get payloadText =>
      maxPayloadKg == null ? '' : '载重 ${_trimDouble(maxPayloadKg!)} kg';

  /// 系统报价展示（只读；成交价必须严格等于该值）。
  String get quotedAmountText =>
      quotedAmount == null ? '' : '¥${_trimDouble(quotedAmount!)}';

  /// 应征时间展示（截断到分钟，与 TaskVo.formattedCreateTime 口径一致）。
  String get formattedAppliedAt {
    final value = appliedAt;
    if (value == null || value.isEmpty) return '';
    final normalized = value.replaceAll('T', ' ');
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
  }

  static String _trimDouble(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }
}
