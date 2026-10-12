// OrderVo 模型解析测试（t41 设备映射契约：deviceId/liveState 三态）。

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/order_api.dart';

void main() {
  test('缺失状态不能被误判为待支付', () {
    final order = OrderVo.fromJson({'orderNum': 'ORD-MISSING'});
    expect(order.isPending, isFalse);
    expect(order.statusLabel, '状态待确认');
    expect(order.totalAmount, isNull);
  });

  test('服务端零元金额保留，不能当成缺失报价', () {
    final order = OrderVo.fromJson({
      'orderNum': 'ORD-ZERO',
      'orderStatus': 1,
      'totalAmount': 0,
    });
    expect(order.totalAmount, 0);
    expect(order.statusLabel, '已支付');
  });
  Map<String, dynamic> baseJson({String? deviceId, String? liveState}) {
    return {
      'orderNum': 'ORD-1',
      'totalAmount': 128.5,
      'distance': 3200,
      'taskName': '航拍任务',
      'orderStatus': 0,
      'deviceId': deviceId,
      'liveState': liveState,
    };
  }

  group('OrderVo.deviceId/liveState（t41 契约）', () {
    test('有值：解析设备与直播态', () {
      final vo = OrderVo.fromJson(
        baseJson(deviceId: 'UAV-001', liveState: 'RUNNING'),
      );
      expect(vo.deviceId, 'UAV-001');
      expect(vo.liveState, 'RUNNING');
      expect(vo.statusLabel, '待支付');
    });

    test('null 值容忍', () {
      final vo = OrderVo.fromJson(baseJson());
      expect(vo.deviceId, isNull);
      expect(vo.liveState, isNull);
    });

    test('字段缺失不崩（宽容解析）', () {
      final json = baseJson()
        ..remove('deviceId')
        ..remove('liveState');
      final vo = OrderVo.fromJson(json);
      expect(vo.deviceId, isNull);
      expect(vo.liveState, isNull);
      expect(vo.orderNum, 'ORD-1');
    });
  });
}
