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
  final double? reward;
  final double? weight;
  final String? taskTime;

  CreateTaskRequest({
    required this.taskName,
    required this.type,
    required this.description,
    required this.waypoints,
    this.reward,
    this.weight,
    this.taskTime,
  });

  Map<String, dynamic> toJson() => {
        'taskName': taskName,
        'type': type,
        'description': description,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        if (reward != null) 'reward': reward,
        if (weight != null) 'weight': weight,
        if (taskTime != null) 'taskTime': taskTime,
      };
}
