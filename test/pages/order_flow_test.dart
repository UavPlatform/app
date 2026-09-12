// 订单流程端到端冒烟（t29）：列表（PENDING）→ 收银台支付 → PAID 全程可见。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/order_api.dart';
import 'package:uav_pilot_app/pages/orders/order_list_page.dart';
import 'package:uav_pilot_app/pages/pay/pay_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  testWidgets('订单列表 PENDING → 收银台模拟支付 → PAID 全程可见可操作', (tester) async {
    var listCall = 0;
    var payCall = 0;
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/order/list') {
        listCall += 1;
        final status = listCall == 1 ? OrderStatusCode.pending : OrderStatusCode.paid;
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orders': [
              {
                'orderNum': 'ORD-1',
                'totalAmount': 128.5,
                'distance': 3200,
                'taskName': '航拍任务',
                'orderStatus': status,
              },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': 1,
          },
        });
      }
      if (path == '/order/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-1',
            'totalAmount': 128.5,
            'distance': 3200,
            'taskName': '航拍任务',
            'orderStatus': OrderStatusCode.pending,
          },
        });
      }
      if (path == '/pay/ORD-1') {
        payCall += 1;
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-1',
            'prepayId': 'mock-prepay-ORD-1',
            'payUrl': '',
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          httpClientProvider.overrideWithValue(
            HttpClient(TokenStorage(prefs), adapter: adapter),
          ),
        ],
        child: const MaterialApp(home: OrderListPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 待支付订单卡片：状态标签 + 去支付入口 + 金额
    expect(find.text('待支付'), findsWidgets);
    expect(find.text('去支付'), findsOneWidget);
    expect(find.text('¥128.50'), findsOneWidget);
    expect(find.textContaining('ORD-1'), findsOneWidget);

    // 去支付 → 模拟收银台
    await tester.tap(find.text('去支付'));
    await tester.pumpAndSettle();
    expect(find.byType(PayPage), findsOneWidget);
    expect(find.text('应付金额'), findsOneWidget);
    expect(find.text('¥128.50'), findsWidgets);
    expect(find.text('模拟支付 ¥128.50'), findsOneWidget);

    // 模拟支付 → POST /pay/{orderNum} → 成功弹窗
    // 注意：提交态 spinner 为持续动画，此处用固定 pump 而非 pumpAndSettle
    await tester.tap(find.text('模拟支付 ¥128.50'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(payCall, 1);
    expect(find.text('支付成功'), findsOneWidget);
    expect(find.textContaining('mock-prepay-ORD-1'), findsOneWidget);

    // 关闭弹窗 → 返回列表 → 自动重载 → PAID
    await tester.tap(find.text('好的'));
    await tester.pumpAndSettle();
    expect(find.byType(PayPage), findsNothing);
    expect(find.text('已支付'), findsWidgets);
    expect(find.text('去支付'), findsNothing, reason: '已支付订单不再展示支付入口');

    // 清理 SnackBar 自动消退定时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(listCall, 2, reason: '支付成功后列表自动重载');
  });

  testWidgets('订单详情视图展示状态流转与订单信息', (tester) async {
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/order/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orders': [
              {
                'orderNum': 'ORD-2',
                'totalAmount': 99,
                'distance': 2000,
                'taskName': '巡检任务',
                'orderStatus': OrderStatusCode.paid,
              },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': 1,
          },
        });
      }
      if (path == '/order/detail') {
        expect(options.uri.queryParameters['orderNum'], 'ORD-2');
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-2',
            'totalAmount': 99,
            'distance': 2000,
            'taskName': '巡检任务',
            'orderStatus': OrderStatusCode.paid,
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          httpClientProvider.overrideWithValue(
            HttpClient(TokenStorage(prefs), adapter: adapter),
          ),
        ],
        child: const MaterialApp(home: OrderListPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 点击订单卡片进入订单详情视图
    await tester.tap(find.textContaining('ORD-2'));
    await tester.pumpAndSettle();

    expect(find.text('订单详情'), findsOneWidget);
    expect(find.text('当前状态: 已支付'), findsOneWidget);
    // 状态流转四步标签齐全
    expect(find.text('待支付'), findsOneWidget);
    expect(find.text('已支付'), findsWidgets);
    expect(find.text('待验收'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('订单编号'), findsOneWidget);
    expect(find.textContaining('ORD-2'), findsOneWidget);
    expect(find.text('¥99.00'), findsOneWidget);
    expect(find.text('订单金额'), findsOneWidget);
  });
}
