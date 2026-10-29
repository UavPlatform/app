import 'package:latlong2/latlong.dart';
import 'dispatch_order.dart';

/// REQ-ALL-XC-004: map positions and progress come only from the current order.
LatLng? dispatchStart(DispatchOrder order) {
  final fields = order.data.fields ?? const <String, dynamic>{};
  final lat = double.tryParse('${fields['start.lat']}');
  final lng = double.tryParse('${fields['start.lng']}');
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180 ||
      lat == 0 && lng == 0) {
    return null;
  }
  return LatLng(lat, lng);
}

class DispatchMapStop {
  DispatchMapStop(this.id, this.point, this.orders);
  final String id;
  final LatLng point;
  final List<DispatchOrder> orders;
  String get label => orders.length > 1
      ? '${orders.length} 单 · 查看进度'
      : orders.single.stageLabel;
}

List<DispatchMapStop> dispatchMapStops(List<DispatchOrder> orders) {
  final groups = <String, DispatchMapStop>{};
  for (final order in orders) {
    final point = dispatchStart(order);
    if (point == null) continue;
    final id =
        '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
    groups
        .putIfAbsent(id, () => DispatchMapStop(id, point, []))
        .orders
        .add(order);
  }
  return groups.values.toList();
}

class DispatchTrackingStep {
  const DispatchTrackingStep(this.label, {this.time, this.current = false});
  final String label;
  final String? time;
  final bool current;
}

List<DispatchTrackingStep> dispatchTrackingSteps(DispatchOrder order) {
  final data = order.data;
  if (order.cancelled) {
    return [
      DispatchTrackingStep('订单提交成功', time: data.createdAt),
      DispatchTrackingStep('订单已取消', time: data.updatedAt, current: true),
    ];
  }
  const stages = [
    'AWAITING_DEPOSIT',
    'WAITING_ACCEPTANCE',
    'PILOT_PREPARING',
    'PILOT_ARRIVED',
    'IN_TRANSIT',
    'DELIVERY_CONFIRMATION',
    'COMPLETED',
  ];
  final current = stages.indexOf(data.stage!);
  final result = <DispatchTrackingStep>[
    DispatchTrackingStep('订单提交成功', time: data.createdAt),
  ];
  if (current == 0) {
    result.add(
      DispatchTrackingStep('待付定金', time: data.createdAt, current: true),
    );
    return result;
  }
  result.add(DispatchTrackingStep('定金已模拟支付', time: data.depositPaidAt));
  const labels = [
    '等待飞手接单',
    '飞手已接单，准备中',
    '飞手已确认到场',
    '飞手已确认开始运输',
    '飞手已提交送达，待确认',
    '已确认收货，运单结单',
  ];
  final times = <String?>[
    data.waitingSince,
    data.acceptedAt,
    data.arrivedAt,
    data.startedAt,
    data.deliveredAt,
    data.receiptAt,
  ];
  for (var index = 1; index <= current; index++) {
    result.add(
      DispatchTrackingStep(
        labels[index - 1],
        time: times[index - 1],
        current: index == current,
      ),
    );
  }
  return result;
}

String dispatchTrackingTime(String? raw) {
  if (raw == null) return '时间未记录';
  final time = DateTime.tryParse(raw);
  if (time == null) return '时间未记录';
  final local = time.isUtc ? time.toLocal() : time;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
