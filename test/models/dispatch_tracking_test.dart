import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/models/dispatch_tracking.dart';
import '../dispatch_order_test_support.dart';

DispatchOrder trackingOrder(
  String id, {
  String stage = 'WAITING_ACCEPTANCE',
  Map<String, dynamic>? fields,
}) => DispatchOrder(
  ApiDispatchOrderVO.fromJson(
    orderJson(stage: stage, funds: 'PAID')
      ..['orderId'] = id
      ..['assignedPilotId'] = 77
      ..['assignmentVersion'] = 2
      ..['createdAt'] = '2026-10-24T13:49:00'
      ..['fields'] = (fields ?? {'start.lat': '27.9', 'start.lng': '112.9'}),
  ),
);

void main() {
  test('timeline uses each server event time rather than the last update', () {
    final data = trackingOrder('timed', stage: 'IN_TRANSIT').data.toJson()
      ..['depositPaidAt'] = '2026-10-24T14:00:00'
      ..['waitingSince'] = '2026-10-24T14:00:00'
      ..['acceptedAt'] = '2026-10-24T14:05:00'
      ..['arrivedAt'] = '2026-10-24T14:10:00'
      ..['startedAt'] = '2026-10-24T14:15:00'
      ..['updatedAt'] = '2026-10-24T19:55:00';
    final steps = dispatchTrackingSteps(
      DispatchOrder(ApiDispatchOrderVO.fromJson(data)),
    );
    expect(steps.skip(1).map((step) => dispatchTrackingTime(step.time)), [
      '10-24 14:00',
      '10-24 14:00',
      '10-24 14:05',
      '10-24 14:10',
      '10-24 14:15',
    ]);
  });
  test(
    'redispatch keeps original payment and shows only the new waiting round',
    () {
      final data = trackingOrder('redispatched').data.toJson()
        ..['depositPaidAt'] = '2026-10-24T14:00:00'
        ..['waitingSince'] = '2026-10-24T15:00:00'
        ..['acceptedAt'] = null
        ..['arrivedAt'] = null;
      final steps = dispatchTrackingSteps(
        DispatchOrder(ApiDispatchOrderVO.fromJson(data)),
      );
      expect(steps, hasLength(3));
      expect(dispatchTrackingTime(steps[1].time), '10-24 14:00');
      expect(dispatchTrackingTime(steps.last.time), '10-24 15:00');
      expect(steps.last.current, isTrue);
    },
  );
  test(
    'unpaid stage begins at creation and unknown history never uses updatedAt',
    () {
      final unpaid = dispatchTrackingSteps(
        trackingOrder('unpaid', stage: 'AWAITING_DEPOSIT'),
      );
      expect(unpaid.last.time, unpaid.first.time);
      final data = trackingOrder('legacy', stage: 'PILOT_ARRIVED').data.toJson()
        ..['updatedAt'] = '2026-10-29T13:00:00';
      final steps = dispatchTrackingSteps(
        DispatchOrder(ApiDispatchOrderVO.fromJson(data)),
      );
      expect(steps.skip(1).every((step) => step.time == null), isTrue);
    },
  );
  test(
    'coincident starts group all orders; invalid coordinates never become fabricated pins',
    () {
      final orders = [
        trackingOrder('a'),
        trackingOrder('b'),
        trackingOrder('c', fields: {'start.lat': 'NaN', 'start.lng': '112'}),
        trackingOrder('d', fields: {'start.lat': '91', 'start.lng': '112'}),
        trackingOrder('e', fields: {}),
      ];
      final stops = dispatchMapStops(orders);
      expect(stops, hasLength(1));
      expect(stops.single.orders.map((order) => order.id), ['a', 'b']);
      expect(stops.single.label, '2 单 · 查看进度');
    },
  );
  test(
    'waiting round never presents old assignment stages as already completed',
    () {
      final steps = dispatchTrackingSteps(trackingOrder('a'));
      expect(steps.map((step) => step.label), ['订单提交成功', '定金已模拟支付', '等待飞手接单']);
      expect(steps.where((step) => step.current).single.label, '等待飞手接单');
      expect(steps[1].time, isNull);
      expect(dispatchTrackingTime(steps[1].time), '时间未记录');
    },
  );
  test(
    'completed timeline uses server timestamps and cancelled orders stop at cancellation',
    () {
      final complete = trackingOrder('a', stage: 'COMPLETED');
      final data = complete.data.toJson()
        ..['startedAt'] = '2026-10-24T14:00:00'
        ..['deliveredAt'] = '2026-10-24T14:16:00'
        ..['receiptAt'] = '2026-10-24T14:35:00';
      final steps = dispatchTrackingSteps(
        DispatchOrder(ApiDispatchOrderVO.fromJson(data)),
      );
      expect(steps.last.current, isTrue);
      expect(dispatchTrackingTime(steps.last.time), '10-24 14:35');
      expect(steps[5].time, '2026-10-24T14:00:00');
      final cancelled = dispatchTrackingSteps(
        trackingOrder('b', stage: 'CANCELLED'),
      );
      expect(cancelled, hasLength(2));
      expect(cancelled.last.label, '订单已取消');
    },
  );
}
