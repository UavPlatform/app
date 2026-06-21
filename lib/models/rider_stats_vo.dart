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
    return RiderStatsVo(
      riderId: (json['riderId'] as num?)?.toInt(),
      riderName: json['riderName'] as String?,
      todayOrders: (json['todayOrders'] as num?)?.toInt() ?? 0,
      totalCompleted: (json['totalCompleted'] as num?)?.toInt() ?? 0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0,
    );
  }
}
