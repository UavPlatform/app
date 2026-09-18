import '../api/generated/openapi_models.dart';

class RiderVo {
  final int riderId;
  final String riderName;
  final int todayOrders;
  final int totalCompleted;
  final double totalEarnings;

  RiderVo({
    required this.riderId,
    required this.riderName,
    required this.todayOrders,
    required this.totalCompleted,
    required this.totalEarnings,
  });

  factory RiderVo.fromJson(Map<String, dynamic> json) {
    final c = ApiRiderStatsVO.fromJson(json);
    return RiderVo(
      riderId: c.riderId as int,
      riderName: c.riderName as String,
      todayOrders: c.todayOrders as int,
      totalCompleted: c.totalCompleted as int,
      totalEarnings: c.totalEarnings as double,
    );
  }
}
