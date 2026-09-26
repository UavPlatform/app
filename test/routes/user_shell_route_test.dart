// TASK-APP-001：用户 Shell 三 Tab 与消息路由重构验证（REQ-APP-002 验收 1）。
//
// 覆盖：
//   1. 登录后底部导航仅三 Tab（首页/订单/我的），且可依次切换；
//   2. `/messages` 旧深链重定向到 `/orders`，不再进入 MessageListPage；
//   3. 全局未读徽标从首页移入订单列表项（占位实现）。

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/main.dart';
import 'package:uav_pilot_app/pages/home/home_page.dart';
import 'package:uav_pilot_app/pages/messages/message_list_page.dart';
import 'package:uav_pilot_app/pages/orders/order_list_page.dart';
import 'package:uav_pilot_app/pages/profile/profile_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/routes/app_router.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import 'package:uav_pilot_app/widgets/app_bottom_nav.dart';

import '../test_support.dart';

/// 登录态启动真实 App：桩 HTTP（默认 success=false），WS 用假 socket。
Future<ProviderContainer> pumpLoggedInApp(
  WidgetTester tester, {
  Future<ResponseBody> Function(RequestOptions options)? handler,
}) async {
  SharedPreferences.setMockInitialValues({
    'jwt_token': makeJwt(userId: 7),
    'jwt_refresh_token': 'r-1',
    'server_url': 'http://stub.local:8081',
  });
  final prefs = await SharedPreferences.getInstance();
  final stub = StubAdapter(
    handler ??
        (options) async => jsonResponse(200, {'success': false, 'message': 'stub'}),
  );
  final client = HttpClient(TokenStorage(prefs), adapter: stub);

  final factory = ScriptedSocketFactory()
    ..enqueueSocket(FakeChatSocket())
    ..enqueueSocket(FakeChatSocket())
    ..enqueueSocket(FakeChatSocket());
  final chatService = ChatWebSocketService(
    TokenStorage(prefs),
    socketFactory: factory.call,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(client),
        chatWebSocketServiceProvider.overrideWithValue(chatService),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();

  return ProviderScope.containerOf(
    tester.element(find.byType(BottomNavigationBar)),
  );
}

/// 订单列表桩：两笔订单（全部 Tab 下 ORD-1 为首项）。
Future<ResponseBody> _orderListStub(RequestOptions options) async {
  if (options.uri.path == '/order/list') {
    return jsonResponse(200, {
      'success': true,
      'code': 200,
      'data': {
        'orders': [
          {'orderNum': 'ORD-1', 'totalAmount': 128.5, 'orderStatus': 0},
          {'orderNum': 'ORD-2', 'totalAmount': 66.0, 'orderStatus': 1},
        ],
        'currentPage': 0,
        'totalPages': 1,
        'totalElements': 2,
      },
    });
  }
  return jsonResponse(200, {'success': false, 'message': 'stub'});
}

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });

  testWidgets('用户 Shell 仅三 Tab，且可依次切换首页/订单/我的', (tester) async {
    await pumpLoggedInApp(tester);

    // 已登录 → 首页，底部导航存在
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.items, hasLength(3), reason: '用户 Shell 只保留三 Tab');
    expect(
      nav.items.map((i) => i.label).toList(),
      ['首页', '订单', '我的'],
      reason: '一级「消息」Tab 已移除（REQ-APP-002）',
    );
    expect(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('消息'),
      ),
      findsNothing,
    );

    // 首页 → 订单
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('订单'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderListPage), findsOneWidget);

    // 订单 → 我的
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('我的'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);

    // 我的 → 首页
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('首页'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('/messages 深链重定向到 /orders，不再进入消息列表', (tester) async {
    final container = await pumpLoggedInApp(tester);
    final router = container.read(goRouterProvider);

    router.go('/messages');
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/orders',
      reason: '废弃的一级消息路由深链统一落到订单列表',
    );
    expect(find.byType(OrderListPage), findsOneWidget);
    expect(find.byType(MessageListPage), findsNothing);
    // 落在订单 Tab（索引 1）
    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.currentIndex, 1);
  });

  testWidgets('全局未读从首页徽标移入订单列表项（占位）', (tester) async {
    await pumpLoggedInApp(
      tester,
      handler: (options) async {
        if (options.uri.path == '/chat/session/list') {
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'data': [
              {
                'id': 11,
                'name': '会话A',
                'type': 0,
                'userIds': [1, 7],
                'otherUserName': '飞手A',
                'lastMessage': '收到',
                'createTime': 1,
                'unreadCount': 7,
              },
            ],
          });
        }
        return _orderListStub(options);
      },
    );

    // 首页不再展示全局未读徽标
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(Badge), findsNothing);

    // 进入订单列表：未读占位徽标挂在首条订单项上
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('订单'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OrderListPage), findsOneWidget);
    expect(find.text('7'), findsOneWidget, reason: '订单列表项展示未读数占位');
    expect(find.textContaining('ORD-2'), findsOneWidget);
  });
}
