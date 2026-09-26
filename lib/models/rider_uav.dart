import '../api/generated/openapi_models.dart';

class RiderUav {
  final int id;
  final int userId;
  final String djiId;

  /// 绑定设备映射的机型 ID（t41/吊运应征门禁：服务端要求应征机型与
  /// 绑定设备映射一致；null = 旧注册路径未映射机型，吊运应征会被拒绝）。
  final int? aircraftModelId;
  final String? createTime;

  RiderUav({
    required this.id,
    required this.userId,
    required this.djiId,
    this.aircraftModelId,
    this.createTime,
  });

  factory RiderUav.fromJson(Map<String, dynamic> json) {
    final c = ApiRiderUav.fromJson(json);
    return RiderUav(
      id: c.id as int,
      userId: c.userId as int,
      djiId: c.djiId as String,
      aircraftModelId: c.aircraftModelId,
      createTime: c.createTime,
    );
  }
}
