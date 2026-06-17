class PilotInfo {
  final String id;
  final String nickname;
  final String? avatar;
  final double rating;
  final int completedOrders;
  final List<String> serviceTypes;
  final bool isVerified;
  final String? introduction;

  PilotInfo({
    required this.id,
    required this.nickname,
    this.avatar,
    required this.rating,
    required this.completedOrders,
    required this.serviceTypes,
    this.isVerified = false,
    this.introduction,
  });
}
