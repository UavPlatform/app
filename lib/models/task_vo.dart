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
