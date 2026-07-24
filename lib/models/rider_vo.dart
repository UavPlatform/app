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
    return RiderVo(
      riderId: json['riderId'] as int,
      riderName: json['riderName'] as String,
      todayOrders: json['todayOrders'] as int,
      totalCompleted: json['totalCompleted'] as int,
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
    );
  }
}
