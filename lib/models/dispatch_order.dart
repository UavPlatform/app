import '../api/dispatch_api.dart';
import '../api/generated/openapi_models.dart';

String dispatchWeightLabel(Map<String, dynamic> fields) {
  final min = (fields['weightMin'] ?? '').toString();
  final max = (fields['weightMax'] ?? '').toString();
  return max.isEmpty ? '$min kg' : '$min–$max kg';
}

class DispatchReadiness {
  const DispatchReadiness(this.enabled, this.blockers);
  final bool enabled;
  final List<String> blockers;
  factory DispatchReadiness.fromApi(ApiDispatchReadinessVO data) {
    if (data.orderingEnabled == null || data.paymentMode != 'SIMULATED') {
      throw const DispatchApiException('暂不支持当前下单通道');
    }
    return DispatchReadiness(data.orderingEnabled!, data.blockers ?? const []);
  }
}

class DispatchAssessment {
  DispatchAssessment(this.data) {
    if (data.assessmentId == null ||
        data.evaluation == null ||
        data.orderAllowed == null) {
      throw const DispatchApiException('评估结果不完整，请重新评估');
    }
  }
  final ApiWaybillAssessmentVO data;
  String get id => data.assessmentId!;
  bool get allowed => data.orderAllowed!;
}

class DispatchOrder {
  DispatchOrder(this.data) {
    if (data.orderId == null ||
        data.orderId!.isEmpty ||
        data.currency != 'CNY' ||
        data.paymentMode != 'SIMULATED' ||
        !const [
          'AWAITING_DEPOSIT',
          'WAITING_ACCEPTANCE',
          'CANCELLED',
          'PILOT_PREPARING',
          'PILOT_ARRIVED',
          'IN_TRANSIT',
          'DELIVERY_CONFIRMATION',
          'COMPLETED',
        ].contains(data.stage) ||
        !const [
          'UNPAID',
          'PAID',
          'REFUNDED',
          'BALANCE_DUE',
          'SETTLED',
        ].contains(data.fundsStatus) ||
        data.depositAmount == null ||
        !data.depositAmount!.isFinite ||
        data.depositAmount! <= 0) {
      throw const DispatchApiException('订单状态暂无法识别，请刷新查询');
    }
    if ((preparing || arrived || transporting || confirming || completed) &&
        (data.assignedPilotId == null || (data.assignmentVersion ?? 0) < 1)) {
      throw const DispatchApiException('接单版本不完整，请刷新查询');
    }
  }
  final ApiDispatchOrderVO data;
  String get id => data.orderId!;
  bool get awaitingDeposit => data.stage == 'AWAITING_DEPOSIT';
  bool get waiting => data.stage == 'WAITING_ACCEPTANCE';
  bool get cancelled => data.stage == 'CANCELLED';
  bool get preparing => data.stage == 'PILOT_PREPARING';
  bool get arrived => data.stage == 'PILOT_ARRIVED';
  bool get transporting => data.stage == 'IN_TRANSIT';
  bool get confirming => data.stage == 'DELIVERY_CONFIRMATION';
  bool get completed => data.stage == 'COMPLETED';
  String get stageLabel => const {
    'AWAITING_DEPOSIT': '待付定金',
    'WAITING_ACCEPTANCE': '等待接单',
    'PILOT_PREPARING': '飞手准备中',
    'PILOT_ARRIVED': '飞手已到场',
    'IN_TRANSIT': '运输中',
    'DELIVERY_CONFIRMATION': '送达双确认',
    'COMPLETED': '已结单',
    'CANCELLED': '已取消',
  }[data.stage]!;
}

class DispatchOffer {
  DispatchOffer(this.data) {
    if (data.orderId == null ||
        data.offerRevision == null ||
        data.offerRevision! < 0 ||
        data.fields == null) {
      throw const DispatchApiException('大厅订单数据不完整，请刷新');
    }
  }
  final ApiDispatchOfferVO data;
  String get id => data.orderId!;
}

class DispatchHall {
  DispatchHall(ApiDispatchHallVO data)
    : items = (data.items ?? []).map(DispatchOffer.new).toList(),
      page = data.page ?? 0,
      hasNext = data.hasNext ?? false;
  final List<DispatchOffer> items;
  final int page;
  final bool hasNext;
}
