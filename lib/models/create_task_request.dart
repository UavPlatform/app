class WaypointRequest {
  final int orderIndex;
  final double longitude;
  final double latitude;
  final double? altitude;

  WaypointRequest({
    required this.orderIndex,
    required this.longitude,
    required this.latitude,
    this.altitude,
  });

  Map<String, dynamic> toJson() => {
        'orderIndex': orderIndex,
        'longitude': longitude,
        'latitude': latitude,
        'altitude': altitude,
      };
}

class CreateTaskRequest {
  final String taskName;
  final String type;
  final String description;
  final List<WaypointRequest> waypoints;
  final String? taskTime;

  /// 吊运货物重量（kg），ADR-0003 报价公式因子（后端 TaskDto.cargoWeightKg）。
  final double? cargoWeightKg;

  /// 吊运货物类别（CONSTRUCTION/EQUIPMENT/AGRICULTURAL，后端 TaskDto.cargoCategory）。
  ///
  /// cargoWeightKg/cargoCategory 为门面层补充入参：vendored OpenAPI 规格
  /// 尚未同步后端 TASK-BACKEND-003 的货物字段（契约同步见 TASK-PLATFORM-001），
  /// 故不走生成模型，由本请求体直发。
  final String? cargoCategory;

  CreateTaskRequest({
    required this.taskName,
    required this.type,
    required this.description,
    required this.waypoints,
    this.taskTime,
    this.cargoWeightKg,
    this.cargoCategory,
  });

  Map<String, dynamic> toJson() => {
        'taskName': taskName,
        'type': type,
        'description': description,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        if (taskTime != null) 'taskTime': taskTime,
        if (cargoWeightKg != null) 'cargoWeightKg': cargoWeightKg,
        if (cargoCategory != null) 'cargoCategory': cargoCategory,
      };
}
