// OrderApi 契约测试（t29：/order/list、/order/detail、/pay/{orderNum}）。

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/order_api.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  Future<HttpClient> clientWith(
    Map<String, Object> prefsValues,
    StubAdapter adapter,
  ) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return HttpClient(TokenStorage(prefs), adapter: adapter);
  }

  group('OrderStatusCode 标签映射', () {
    test('0-5 全状态中文标签（WAITING_CONFIRM 展示为待验收）', () {
      expect(OrderStatusCode.labelOf(OrderStatusCode.pending), '待支付');
      expect(OrderStatusCode.labelOf(OrderStatusCode.paid), '已支付');
      expect(OrderStatusCode.labelOf(OrderStatusCode.cancelled), '已取消');
      expect(OrderStatusCode.labelOf(OrderStatusCode.refunded), '已退款');
      expect(OrderStatusCode.labelOf(OrderStatusCode.completed), '已完成');
      expect(OrderStatusCode.labelOf(OrderStatusCode.waitingConfirm), '待验收');
      expect(OrderStatusCode.labelOf(OrderStatusCode.matching), '撮合中');
      expect(OrderStatusCode.labelOf(OrderStatusCode.disputed), '争议中');
      expect(OrderStatusCode.labelOf(99), '未知状态');
    });
  });

  group('/order/list', () {
    test('解析订单分页（orders/currentPage/totalPages/totalElements）', () async {
      final adapter = StubAdapter((options) async {
        expect(options.uri.path, '/order/list');
        expect(options.uri.queryParameters['page'], '0');
        expect(options.uri.queryParameters['size'], '20');
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orders': [
              {
                'orderNum': 'ORD20260912-001',
                'totalAmount': 128.5,
                'distance': 3200,
                'taskName': '航拍任务',
                'orderStatus': 0,
              },
              {
                'orderNum': 'ORD20260912-002',
                'totalAmount': 66,
                'distance': 1500,
                'taskName': '测绘任务',
                'orderStatus': 1,
              },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': 2,
          },
        });
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'server_url': 'http://stub.local:8081',
      }, adapter);

      final result = await OrderApi(client).listOrders();

      expect(result.success, true);
      expect(result.data!.orders, hasLength(2));
      expect(result.data!.orders[0].orderNum, 'ORD20260912-001');
      expect(result.data!.orders[0].totalAmount, 128.5);
      expect(result.data!.orders[0].statusLabel, '待支付');
      expect(result.data!.orders[0].isPending, true);
      expect(result.data!.orders[1].orderStatus, OrderStatusCode.paid);
      expect(result.data!.orders[1].statusLabel, '已支付');
      expect(result.data!.totalElements, 2);
    });
  });

  group('/order/detail', () {
    test('按 orderNum 查询并解析', () async {
      final adapter = StubAdapter((options) async {
        expect(options.uri.path, '/order/detail');
        expect(options.uri.queryParameters['orderNum'], 'ORD-1');
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-1',
            'totalAmount': 99,
            'distance': 2000,
            'taskName': '巡检任务',
            'orderStatus': 5,
          },
        });
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'server_url': 'http://stub.local:8081',
      }, adapter);

      final result = await OrderApi(client).getOrderDetail('ORD-1');

      expect(result.success, true);
      expect(result.data!.orderNum, 'ORD-1');
      expect(result.data!.statusLabel, '待验收');
      expect(result.data!.distance, 2000.0);
    });
  });

  group('POST /pay/{orderNum}（t21 mock 通道）', () {
    test('发起支付并解析 PayResultVo，默认不携带 openid', () async {
      final adapter = StubAdapter((options) async {
        expect(options.uri.path, '/pay/ORD-1');
        expect(options.uri.queryParameters.containsKey('openid'), false);
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-1',
            'prepayId': 'mock-prepay-ORD-1',
            'payUrl': '',
          },
        });
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'server_url': 'http://stub.local:8081',
      }, adapter);

      final result = await OrderApi(client).payOrder('ORD-1');

      expect(result.success, true);
      expect(result.data!.orderNum, 'ORD-1');
      expect(result.data!.prepayId, 'mock-prepay-ORD-1');
    });

    test('携带 openid 时作为查询参数传递', () async {
      final adapter = StubAdapter((options) async {
        expect(options.uri.queryParameters['openid'], 'o-123');
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {'orderNum': 'ORD-1', 'prepayId': 'p', 'payUrl': ''},
        });
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'server_url': 'http://stub.local:8081',
      }, adapter);

      final result = await OrderApi(client).payOrder('ORD-1', openid: 'o-123');
      expect(result.success, true);
    });

    test('失败响应透传 message', () async {
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'server_url': 'http://stub.local:8081',
      }, StubAdapter((options) async {
        return jsonResponse(400, {'success': false, 'message': '重复支付'});
      }));

      final result = await OrderApi(client).payOrder('ORD-1');
      expect(result.success, false);
      expect(result.message, '重复支付');
    });
  });
}
