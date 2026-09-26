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
    );
  }

  factory TaskVo.fromJson(Map<String, dynamic> json) =>
      TaskVo.fromApi(ApiTaskVo.fromJson(json));

  String get taskTypeName {
    switch (taskType) {
      case 'AERIAL_PHOTO': return '航拍';
      case 'TRANSPORT': return '调运';
      case 'SURVEY': return '测绘';
      case 'MONITORING': return '监测';
      default: return taskType;
    }
  }

  String get taskStatusName {
    switch (taskStatus) {
      case 'IDLE': return '空闲中';
      case 'IN_PROGRESS': return '执行中';
      case 'COMPLETED': return '已完成';
      default: return taskStatus;
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

  String get priceText {
    if (totalAmount != null && totalAmount! > 0) {
      return '¥${totalAmount!.toStringAsFixed(0)}';
    }
    return '面议';
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
