import '../api/generated/openapi_models.dart';

class RiderUav {
  final int id;
  final int userId;
  final String djiId;
  final String? createTime;

  RiderUav({
    required this.id,
    required this.userId,
    required this.djiId,
    this.createTime,
  });

  factory RiderUav.fromJson(Map<String, dynamic> json) {
    final c = ApiRiderUav.fromJson(json);
    return RiderUav(
      id: c.id as int,
      userId: c.userId as int,
      djiId: c.djiId as String,
      createTime: c.createTime,
    );
  }
}
