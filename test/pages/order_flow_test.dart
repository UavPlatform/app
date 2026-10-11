// 订单流程端到端冒烟（t29）：列表（PENDING）→ 收银台支付 → PAID 全程可见。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/order_api.dart';
import 'package:uav_pilot_app/pages/orders/order_detail_page.dart';
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
        final status = listCall == 1
            ? OrderStatusCode.pending
            : OrderStatusCode.paid;
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
    expect(find.text('待飞手确认'), findsWidgets);
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
    expect(find.text('当前状态: 待飞手确认'), findsOneWidget);
    // 状态流转四步标签齐全
    expect(find.text('待支付'), findsOneWidget);
    expect(find.text('待飞手确认'), findsWidgets);
    expect(find.text('待验收'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('订单编号'), findsOneWidget);
    expect(find.textContaining('ORD-2'), findsOneWidget);
    expect(find.text('¥99.00'), findsOneWidget);
    expect(find.text('订单金额'), findsOneWidget);
  });

  testWidgets('订单卡片按 orderNum 反查任务：阶段文案与首页一致，点击直达撮合中心', (tester) async {
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/order/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orders': [
              {
                'orderNum': 'ORD-3',
                'totalAmount': 980,
                'taskName': '山顶基站建材吊运',
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
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-3',
            'totalAmount': 980,
            'orderStatus': OrderStatusCode.paid,
          },
        });
      }
      if (path == '/task/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'tasks': [
              {
                'id': 3,
                'taskNum': 'T-3',
                'taskName': '山顶基站建材吊运',
                'userId': 7,
                'taskType': 'TRANSPORT',
                'taskStatus': 'IDLE',
                'matchStatus': 'SEEKING_RIDER',
                'orderNum': 'ORD-3',
              },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': 1,
          },
        });
      }
      if (path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'id': 3,
            'taskNum': 'T-3',
            'taskName': '山顶基站建材吊运',
            'userId': 7,
            'taskType': 'TRANSPORT',
            'taskStatus': 'IDLE',
            'matchStatus': 'SEEKING_RIDER',
            'actionHint': '等待飞手应征，选定后下单支付',
            'orderNum': 'ORD-3',
            'orderStatus': 'PAID',
            'totalAmount': 980,
          },
        });
      }
      if (path == '/task/T-3/applications' ||
          path == '/task/T-3/chat-sessions') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();

    final router = GoRouter(
      initialLocation: '/orders',
      routes: [
        GoRoute(path: '/orders', builder: (_, _) => const OrderListPage()),
        GoRoute(
          path: '/order/:taskNum',
          builder: (_, state) =>
              OrderDetailPage(taskNum: state.pathParameters['taskNum']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          httpClientProvider.overrideWithValue(
            HttpClient(TokenStorage(prefs), adapter: adapter),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 卡片阶段标签取任务撮合阶段（REQ-APP-002 文案一致），而不是订单码的「已支付」。
    expect(
      find.descendant(of: find.byType(Card), matching: find.text('招募飞手中')),
      findsOneWidget,
    );
    expect(find.widgetWithText(Tab, '招募飞手中'), findsOneWidget, reason: '分栏同名');

    // 订单卡片 → 直达任务详情（撮合中心：应征列表 + 订单内聊天），不再经过中间页。
    await tester.tap(find.textContaining('ORD-3'));
    await tester.pumpAndSettle();
    expect(find.text('应征飞手与订单聊天'), findsNothing);

    expect(find.byType(OrderDetailPage), findsOneWidget);
    expect(find.text('等待飞手接单'), findsOneWidget, reason: '撮合中心空状态');
    expect(
      find.text('等待飞手应征，选定后下单支付'),
      findsOneWidget,
      reason: '文案来自服务端 actionHint',
    );
  });

  testWidgets('草稿订单：分栏名与卡片标签同为 REQ-APP-002 阶段名，不显示 ¥0.00 与「未知状态」', (
    tester,
  ) async {
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/order/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orders': [
              {
                'orderNum': 'ORD-7',
                'totalAmount': 0,
                'taskName': '基站备用电池吊运',
                'orderStatus': OrderStatusCode.matching,
              },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': 1,
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

    expect(find.text('未知状态'), findsNothing);
    expect(find.text('撮合中'), findsNothing, reason: '同一阶段只用 REQ-APP-002 的一个名字');
    // 分栏「招募飞手中」+ 卡片兜底标签「招募飞手中」（任务反查不到时按订单码 MATCHING）
    expect(find.text('招募飞手中'), findsNWidgets(2));
    expect(find.text('¥0.00'), findsNothing);
    expect(find.text('选定飞手后锁价'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, '洽谈中'));
    await tester.pumpAndSettle();
    expect(find.text('基站备用电池吊运'), findsNothing, reason: '分栏按卡片阶段筛选');

    await tester.tap(find.widgetWithText(Tab, '招募飞手中'));
    await tester.pumpAndSettle();
    expect(find.text('基站备用电池吊运'), findsOneWidget);
  });

  testWidgets('每张卡片都落在某个具体分栏：已付款（反查不到任务）→「待飞手确认」，已取消/已退款/争议中/未知订单码 →「售后/其他」', (
    tester,
  ) async {
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/order/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orders': [
              {
                'orderNum': 'ORD-8',
                'totalAmount': 264.65,
                'taskName': '已付款的吊运单',
                'orderStatus': OrderStatusCode.paid,
              },
              {
                'orderNum': 'ORD-9',
                'totalAmount': 120.0,
                'taskName': '已取消的吊运单',
                'orderStatus': OrderStatusCode.cancelled,
              },
              {
                'orderNum': 'ORD-10',
                'totalAmount': 130.0,
                'taskName': '已退款的吊运单',
                'orderStatus': OrderStatusCode.refunded,
              },
              {
                'orderNum': 'ORD-11',
                'totalAmount': 140.0,
                'taskName': '争议中的吊运单',
                'orderStatus': OrderStatusCode.disputed,
              },
              {
                'orderNum': 'ORD-12',
                'totalAmount': 150.0,
                'taskName': '未知状态码的吊运单',
                'orderStatus': 99,
              },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': 1,
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

    expect(find.text('已支付'), findsNothing, reason: '不使用 REQ-APP-002 状态机之外的阶段名');
    await tester.tap(find.widgetWithText(Tab, '待飞手确认'));
    await tester.pumpAndSettle();
    expect(find.text('已付款的吊运单'), findsOneWidget);
    expect(find.text('已取消的吊运单'), findsNothing);

    await tester.dragUntilVisible(
      find.widgetWithText(Tab, '售后/其他'),
      find.byType(TabBar),
      const Offset(-200, 0),
    );
    await tester.tap(find.widgetWithText(Tab, '售后/其他'));
    await tester.pumpAndSettle();
    // 旁路终态（已取消 / 已退款 / 争议中）与未知订单码都落在兜底栏
    for (final name in ['已取消的吊运单', '已退款的吊运单', '争议中的吊运单', '未知状态码的吊运单']) {
      await tester.dragUntilVisible(
        find.text(name),
        find.byType(ListView).last,
        const Offset(0, -200),
      );
      expect(find.text(name), findsOneWidget, reason: '$name 应在「售后/其他」');
    }
    expect(find.text('已付款的吊运单'), findsNothing);
  });
}
