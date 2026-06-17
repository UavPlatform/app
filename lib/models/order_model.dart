enum OrderStatus {
  pending,      // 待接单
  inProgress,   // 进行中
  reviewing,    // 待验收
  completed,    // 已完成
  cancelled,    // 已取消
}

class Order {
  final String id;
  final String userId;
  final String serviceTypeId;
  final String serviceTypeName;
  final String title;
  final String description;
  final String location;
  final DateTime taskDate;
  final double? budgetMin;
  final double? budgetMax;
  final double? finalPrice;
  final OrderStatus status;
  final String? pilotId;
  final String? pilotName;
  final double? pilotRating;
  final DateTime createdAt;
  final List<String> imageUrls;

  Order({
    required this.id,
    required this.userId,
    required this.serviceTypeId,
    required this.serviceTypeName,
    required this.title,
    required this.description,
    required this.location,
    required this.taskDate,
    this.budgetMin,
    this.budgetMax,
    this.finalPrice,
    required this.status,
    this.pilotId,
    this.pilotName,
    this.pilotRating,
    required this.createdAt,
    this.imageUrls = const [],
  });

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return '待接单';
      case OrderStatus.inProgress:
        return '进行中';
      case OrderStatus.reviewing:
        return '待验收';
      case OrderStatus.completed:
        return '已完成';
      case OrderStatus.cancelled:
        return '已取消';
    }
  }

  String get priceText {
    if (finalPrice != null) {
      return '¥${finalPrice!.toStringAsFixed(0)}';
    }
    if (budgetMin != null && budgetMax != null) {
      return '¥${budgetMin!.toStringAsFixed(0)}-${budgetMax!.toStringAsFixed(0)}';
    }
    return '面议';
  }
}
