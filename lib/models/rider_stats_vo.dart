import '../api/generated/openapi_models.dart';

class RiderStatsVo {
  final int? riderId;
  final String? riderName;
  final int todayOrders;
  final int totalCompleted;
  final double totalEarnings;

  RiderStatsVo({
    this.riderId,
    this.riderName,
    this.todayOrders = 0,
    this.totalCompleted = 0,
    this.totalEarnings = 0,
  });

  factory RiderStatsVo.fromJson(Map<String, dynamic> json) {
    final c = ApiRiderStatsVO.fromJson(json);
    return RiderStatsVo(
      riderId: c.riderId,
      riderName: c.riderName,
      todayOrders: c.todayOrders ?? 0,
      totalCompleted: c.totalCompleted ?? 0,
      totalEarnings: c.totalEarnings ?? 0,
    );
  }
}
