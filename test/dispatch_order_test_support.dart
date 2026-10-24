import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/dispatch_order_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';

Map<String, dynamic> orderJson({
  String stage = 'AWAITING_DEPOSIT',
  String funds = 'UNPAID',
}) => {
  'orderId': 'demo-order',
  'stage': stage,
  'fundsStatus': funds,
  'paymentMode': 'SIMULATED',
  'depositAmount': 125.50,
  'pilotServiceFee': 180.50,
  'currency': 'CNY',
  'fields': <String, String>{},
  'paymentReference': funds == 'UNPAID' ? null : 'sim-pay-demo-order',
  'refundReference': funds == 'REFUNDED' ? 'sim-refund-demo-order' : null,
};

class FakeDispatchOrderApi extends DispatchOrderApi {
  FakeDispatchOrderApi(super.client);
  bool enabled = true;
  bool prohibited = false;
  bool loseCreateResponse = false;
  bool failPayment = false;
  int payments = 0;
  int assessments = 0;
  final keys = <String>[];
  DispatchOrder? order;
  @override
  Future<DispatchReadiness> readiness() async =>
      DispatchReadiness(enabled, enabled ? [] : ['模拟评估未启用']);
  @override
  Future<DispatchAssessment> assess(WaybillDraft draft) async {
    assessments++;
    return DispatchAssessment(
      ApiWaybillAssessmentVO.fromJson({
        'assessmentId': 'demo-assessment',
        'expiresAt': '2099-01-01T12:00:00',
        'orderAllowed': !prohibited,
        'evaluation': {
          'airspace': prohibited ? 'PROHIBITED' : 'CAUTION',
          'source': 'SIMULATED_DEMO',
          'distanceMeters': 1000,
          'flightMinutes': 5,
          'altitudeDifferenceMeters': 20,
          'terrain': '模拟平地',
          'warnings': ['演示样例'],
        },
      }),
    );
  }

  @override
  Future<DispatchOrder> create(
    WaybillDraft draft,
    String assessmentId,
    String requestKey,
  ) async {
    keys.add(requestKey);
    order ??= DispatchOrder(ApiDispatchOrderVO.fromJson(orderJson()));
    if (loseCreateResponse) {
      loseCreateResponse = false;
      throw const DispatchApiException('响应丢失，请查询或重试');
    }
    return order!;
  }

  @override
  Future<DispatchOrder> get(String id) async => order!;
  @override
  Future<List<DispatchOrder>> list() async => order == null ? [] : [order!];
  @override
  Future<DispatchOrder> pay(String id) async {
    payments++;
    if (failPayment) throw const DispatchApiException('模拟付款未确认，请刷新订单');
    return order = DispatchOrder(
      ApiDispatchOrderVO.fromJson(
        orderJson(stage: 'WAITING_ACCEPTANCE', funds: 'PAID'),
      ),
    );
  }

  @override
  Future<DispatchOrder> cancel(String id) async => order = DispatchOrder(
    ApiDispatchOrderVO.fromJson(
      orderJson(
        stage: 'CANCELLED',
        funds: order?.data.fundsStatus == 'PAID' ? 'REFUNDED' : 'UNPAID',
      ),
    ),
  );
}
