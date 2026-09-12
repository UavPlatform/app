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

  factory WaypointVo.fromJson(Map<String, dynamic> json) {
    return WaypointVo(
      id: json['id'] as int,
      orderIndex: json['orderIndex'] as int,
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
    );
  }
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

  factory TaskVo.fromJson(Map<String, dynamic> json) {
    return TaskVo(
      id: json['id'] as int,
      taskNum: json['taskNum'] as String,
      taskName: json['taskName'] as String,
      userId: json['userId'] as int,
      taskType: (json['taskType'] as String?) ?? '',
      taskStatus: (json['taskStatus'] as String?) ?? '',
      description: json['description'] as String?,
      taskTime: json['taskTime'] as String?,
      completeNote: json['completeNote'] as String?,
      actionHint: json['actionHint'] as String?,
      deviceId: json['deviceId'] as String?,
      liveState: json['liveState'] as String?,
      riderId: json['riderId'] as int?,
      riderName: json['riderName'] as String?,
      acceptTime: json['acceptTime'] as String?,
      orderNum: json['orderNum'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      orderStatus: json['orderStatus'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
      waypoints: (json['waypoints'] as List<dynamic>?)
          ?.map((e) => WaypointVo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

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
    return TaskPageVo(
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => TaskVo.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
    );
  }

  static Result<TaskPageVo> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => TaskPageVo.fromJson(data));
  }
}
