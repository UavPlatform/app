import '../api/generated/openapi_models.dart';
import 'result_model.dart';

class WaypointVo {
  final int id;
  final int orderIndex;
  final double longitude;
  final double latitude;
  final double? altitude;

  WaypointVo({
    required this.id,
    required this.orderIndex,
    required this.longitude,
    required this.latitude,
    this.altitude,
  });

  /// 字段直取契约类（ApiWaypointVo）：契约重命名/删除字段时此处编译失败。
  factory WaypointVo.fromApi(ApiWaypointVo c) {
    return WaypointVo(
      id: c.id as int,
      orderIndex: c.orderIndex as int,
      longitude: c.longitude as double,
      latitude: c.latitude as double,
      altitude: c.altitude,
    );
  }

  factory WaypointVo.fromJson(Map<String, dynamic> json) =>
      WaypointVo.fromApi(ApiWaypointVo.fromJson(json));
}

class TaskVo {
  final int id;
  final String taskNum;
  final String taskName;
  final int userId;
  final String taskType;
  final String taskStatus;
  final String? description;
  final String? taskTime;
  final String? completeNote;

  /// 服务端统一计算的任务×订单操作提示（1B-9a 状态矩阵，直接渲染不端上拼装）
  final String? actionHint;

  /// 撮合子状态（ADR-0003 决定 6：SEEKING_RIDER/NEGOTIATING/AWAITING_PAYMENT/
  /// AWAITING_RIDER_CONFIRM/CONFIRMED/PENDING_ACCEPTANCE/CLOSED）。
  /// 仅用于决定详情页撮合区域显隐，文案仍以 actionHint 为唯一来源。
  final String? matchStatus;

  /// 任务关联的作业设备（t41：接单飞手绑定设备中在线的一台；无在线设备为 null）
  final String? deviceId;

  /// 该设备的直播状态（IDLE/STARTING/RUNNING；无设备为 IDLE）
  final String? liveState;
  final int? riderId;
  final String? riderName;
  final String? acceptTime;
  final String? orderNum;
  final double? totalAmount;
  final double? totalDistance;
  final String? orderStatus;
  final String? createTime;
  final String? updateTime;
  final List<WaypointVo>? waypoints;

  // ==================== 吊运撮合字段（TASK-BACKEND-003/004，ADR-0003） ====================

  /// 货物重量 kg（吊运计价输入之一；空 = 任务未填，吊运应征会被服务端拒绝）
  final double? cargoWeightKg;

  /// 货物类别（CONSTRUCTION/EQUIPMENT/AGRICULTURAL）
  final String? cargoCategory;

  /// 选定应征的系统报价（= 成交价 totalAmount，严格相等）；未选定时飞手「我的接单」列表为本人应征的系统报价，其余为 null。
  /// ADR-0003：只读展示，客户端不得改价。
  final double? quotedAmount;

  /// 选定应征的机型（用户下单后可见成交机型；未选定为 null）
  final int? aircraftModelId;
  final String? aircraftModelName;
  final String? modelCode;

  /// 约定作业时间（ADR-0003 决定 4，用户下单时提交；飞手确认前回显）
  final String? scheduledTime;
  final String? userConfirmedAt;
  final String? riderConfirmedAt;

  TaskVo({
    required this.id,
    required this.taskNum,
    required this.taskName,
    required this.userId,
    required this.taskType,
    required this.taskStatus,
    this.description,
    this.taskTime,
    this.completeNote,
    this.actionHint,
    this.matchStatus,
    this.deviceId,
    this.liveState,
    this.riderId,
    this.riderName,
    this.acceptTime,
    this.orderNum,
    this.totalAmount,
    this.totalDistance,
    this.orderStatus,
    this.createTime,
    this.updateTime,
    this.waypoints,
    this.cargoWeightKg,
    this.cargoCategory,
    this.quotedAmount,
    this.aircraftModelId,
    this.aircraftModelName,
    this.modelCode,
    this.scheduledTime,
    this.userConfirmedAt,
    this.riderConfirmedAt,
  });

  /// 字段直取契约类（ApiTaskVo）：契约重命名/删除字段时此处编译失败。
  factory TaskVo.fromApi(ApiTaskVo c) {
    return TaskVo(
      id: c.id as int,
      taskNum: c.taskNum as String,
      taskName: c.taskName as String,
      userId: c.userId as int,
      taskType: c.taskType ?? '',
      taskStatus: c.taskStatus ?? '',
      description: c.description,
      taskTime: c.taskTime,
      completeNote: c.completeNote,
      actionHint: c.actionHint,
      matchStatus: c.matchStatus,
      deviceId: c.deviceId,
      liveState: c.liveState,
      riderId: c.riderId,
      riderName: c.riderName,
      acceptTime: c.acceptTime,
      orderNum: c.orderNum,
      totalAmount: c.totalAmount,
      totalDistance: c.totalDistance,
      orderStatus: c.orderStatus,
      createTime: c.createTime,
      updateTime: c.updateTime,
      waypoints: c.waypoints?.map(WaypointVo.fromApi).toList(),
      cargoWeightKg: c.cargoWeightKg,
      cargoCategory: c.cargoCategory,
      quotedAmount: c.quotedAmount,
      aircraftModelId: c.aircraftModelId,
      aircraftModelName: c.aircraftModelName,
      modelCode: c.modelCode,
      scheduledTime: c.scheduledTime,
      userConfirmedAt: c.userConfirmedAt,
      riderConfirmedAt: c.riderConfirmedAt,
    );
  }

  factory TaskVo.fromJson(Map<String, dynamic> json) =>
      TaskVo.fromApi(ApiTaskVo.fromJson(json));

  String get taskTypeName {
    switch (taskType) {
      case 'AERIAL_PHOTO':
        return '航拍';
      case 'TRANSPORT':
        return '调运';
      case 'SURVEY':
        return '测绘';
      case 'MONITORING':
        return '监测';
      default:
        return taskType;
    }
  }

  String get taskStatusName {
    switch (taskStatus) {
      case 'IDLE':
        return '空闲中';
      case 'IN_PROGRESS':
        return '执行中';
      case 'COMPLETED':
        return '已完成';
      default:
        return taskStatus;
    }
  }

  bool get isIdle => taskStatus == 'IDLE';
  bool get isInProgress => taskStatus == 'IN_PROGRESS';
  bool get isCompleted => taskStatus == 'COMPLETED';
  bool get isWaitingConfirm => orderStatus == 'WAITING_CONFIRM';

  /// 是否处于招募/洽谈阶段（未选定飞手）：决定详情页应征区块的空状态是否展示。
  bool get isInMatchingStage =>
      matchStatus == null ||
      matchStatus == 'SEEKING_RIDER' ||
      matchStatus == 'NEGOTIATING';

  // ==================== 撮合阶段判定（ADR-0003 决定 6，仅控显隐；文案用 actionHint） ====================

  /// 待用户下单（已应征，等待用户选定/支付）
  bool get isAwaitingUserOrder =>
      matchStatus == 'NEGOTIATING' || matchStatus == 'AWAITING_PAYMENT';

  /// 待飞手确认（用户已支付，等待我确认约定时间）
  bool get isAwaitingRiderConfirm => matchStatus == 'AWAITING_RIDER_CONFIRM';

  /// 已确认（可执飞；djifly 执飞门禁点）
  bool get isConfirmedForFlight => matchStatus == 'CONFIRMED';

  /// 我方可发起应征（招募中/洽谈中，且任务未在执行）
  bool get canApply =>
      (matchStatus == null ||
          matchStatus == 'SEEKING_RIDER' ||
          matchStatus == 'NEGOTIATING') &&
      taskStatus == 'IDLE';

  /// 吊运货物摘要（重量 + 类别），无货物字段时返回空串。
  String get cargoLabel {
    final weight = cargoWeightKg;
    final category = cargoCategory;
    if (weight == null && category == null) return '';
    final parts = <String>[
      if (weight != null) '${_trimDouble(weight)} kg',
      if (category != null && category.isNotEmpty) _cargoCategoryName(category),
    ];
    return parts.join(' · ');
  }

  /// 系统报价（只读展示；ADR-0003：成交价必须严格等于该值，客户端不提供改价入口）。
  String get quotedAmountText =>
      quotedAmount == null ? '' : '¥${_trimDouble(quotedAmount!)}';

  /// 约定作业时间（截断到分钟，与 formattedTaskTime 展示口径一致）。
  String get formattedScheduledTime {
    final value = scheduledTime;
    if (value == null || value.isEmpty) return '';
    final normalized = value.replaceAll('T', ' ');
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
  }

  /// 用户确认时间（下单确认约定时间；截断到分钟展示，无则空串）。
  String get formattedUserConfirmedAt => _minuteText(userConfirmedAt);

  /// 飞手确认时间（双确认第二步；截断到分钟展示，无则空串）。
  String get formattedRiderConfirmedAt => _minuteText(riderConfirmedAt);

  static String _minuteText(String? value) {
    if (value == null || value.isEmpty) return '';
    final normalized = value.replaceAll('T', ' ');
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
  }

  static String _cargoCategoryName(String code) {
    switch (code) {
      case 'CONSTRUCTION':
        return '建材';
      case 'EQUIPMENT':
        return '设备';
      case 'AGRICULTURAL':
        return '农产品';
      case 'DAILY_SUPPLIES':
        return '生活物资';
      case 'FURNITURE':
        return '家具家居';
      default:
        return code;
    }
  }

  static String _trimDouble(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  String get priceText {
    if (totalAmount != null && totalAmount! > 0) {
      // 与用户端订单/收银台一致保留两位小数（¥264.65，而不是四舍五入成 ¥265）
      return '¥${totalAmount!.toStringAsFixed(2)}';
    }
    // 尚未锁价（应征中/洽谈中）：飞手视角列表下发本人应征的平台系统报价（ADR-0003，不可改价）
    if (quotedAmount != null && quotedAmount! > 0) {
      return '¥${quotedAmount!.toStringAsFixed(2)}';
    }
    // ADR-0003：平台按规则统一计价、不议价——不显示「面议」；飞手应征后由平台给出系统报价
    return '待平台报价';
  }

  String get formattedCreateTime {
    if (createTime == null) return '';
    return createTime!.replaceAll('T', ' ').substring(0, 16);
  }

  /// 任务时间展示（t15 契约："yyyy-MM-dd HH:mm:ss"，空格分隔）。
  /// 截断到分钟展示，与 formattedCreateTime 的展示口径一致；
  /// 兼容容忍 ISO 'T' 分隔与短格式。
  String get formattedTaskTime {
    final value = taskTime;
    if (value == null || value.isEmpty) return '';
    final normalized = value.replaceAll('T', ' ');
    return normalized.length >= 16 ? normalized.substring(0, 16) : normalized;
  }

  static Result<TaskVo> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => TaskVo.fromJson(data));
  }
}

class TaskPageVo {
  final List<TaskVo> tasks;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  TaskPageVo({
    required this.tasks,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  factory TaskPageVo.fromJson(Map<String, dynamic> json) {
    final c = ApiTaskPageVO.fromJson(json);
    return TaskPageVo(
      tasks: (c.tasks as List<ApiTaskVo>).map(TaskVo.fromApi).toList(),
      currentPage: c.currentPage as int,
      totalPages: c.totalPages as int,
      totalElements: c.totalElements as int,
    );
  }

  static Result<TaskPageVo> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => TaskPageVo.fromJson(data));
  }
}
