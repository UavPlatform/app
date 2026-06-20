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
    return RiderUav(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      djiId: json['djiId'] as String,
      createTime: json['createTime'] as String?,
    );
  }
}
