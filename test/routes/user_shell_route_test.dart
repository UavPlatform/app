// 用户 Shell 路由验证（派单唯一路径）：
//   1. 登录后底部导航三 Tab（首页/创建订单/我的），首页即派单订单列表；
//   2. `/messages` 旧深链重定向到 `/orders`，不再进入 MessageListPage；
//   3. 普通用户不能进入飞手 Shell。

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/main.dart';
import 'package:uav_pilot_app/pages/messages/message_list_page.dart';
import 'package:uav_pilot_app/pages/profile/profile_page.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_order_pages.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/routes/app_router.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import 'package:uav_pilot_app/widgets/app_bottom_nav.dart';

import '../test_support.dart';
import '../map_test_support.dart';
import 'package:uav_pilot_app/models/amap_config.dart';

/// 登录态启动真实 App：桩 HTTP（默认 success=false），WS 用假 socket。
Future<ProviderContainer> pumpLoggedInApp(
  WidgetTester tester, {
  Future<ResponseBody> Function(RequestOptions options)? handler,
  int role = 0,
}) async {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
  mockNativeMaps(tester);
  SharedPreferences.setMockInitialValues({
    'task_flow_guide_dismissed_v1': true,
    'jwt_token': makeJwt(userId: 7, role: role),
    'jwt_refresh_token': 'r-1',
    'server_url': 'http://stub.local:8081',
  });
  final prefs = await SharedPreferences.getInstance();
  final stub = StubAdapter(
    handler ??
        (options) async =>
            jsonResponse(200, {'success': false, 'message': 'stub'}),
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
        amapMapConfigProvider.overrideWith(
          (ref) async => AmapConfig(key: 'test-key', securityKey: ''),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(client),
        chatWebSocketServiceProvider.overrideWithValue(chatService),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();

  return ProviderScope.containerOf(tester.element(find.byType(MyApp)));
}

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });

  testWidgets('用户 Shell 三 Tab：首页为派单订单列表，可切换到我的并返回', (tester) async {
    await pumpLoggedInApp(tester);

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(DispatchOrderListPage), findsOneWidget);

    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.items.map((i) => i.label).toList(), ['首页', '创建订单', '我的']);
    expect(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('消息'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('我的'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('首页'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DispatchOrderListPage), findsOneWidget);
  });

  testWidgets('/messages 深链重定向，不再进入消息列表', (tester) async {
    final container = await pumpLoggedInApp(tester);
    final router = container.read(goRouterProvider);

    router.go('/messages');
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      isNot('/messages'),
    );
    expect(find.byType(DispatchOrderListPage), findsOneWidget);
    expect(find.byType(MessageListPage), findsNothing);
  });

  testWidgets('Ordinary users cannot navigate into the pilot shell', (
    tester,
  ) async {
    final container = await pumpLoggedInApp(tester);
    final router = container.read(goRouterProvider);
    router.go('/pilot/tasks');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(tester.takeException(), isNull);
  });
}
