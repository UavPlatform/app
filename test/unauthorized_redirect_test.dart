// 401 刷新失败端到端冒烟：真实 MyApp + 路由守卫（P1-4）。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/main.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_order_pages.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import 'test_support.dart';

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });

  testWidgets('401 刷新失败触发登出并直达登录页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();

    // 所有 HTTP 请求返回 success=false（不触发 401 循环，首页呈现错误/空态）
    final stub = StubAdapter((options) async {
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
    final client = HttpClient(TokenStorage(prefs), adapter: stub);

    final factory = ScriptedSocketFactory()
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

    // 已登录 → 首页；WS 已按登录身份建立
    expect(find.byType(DispatchOrderListPage), findsOneWidget, reason: '已登录应落在首页');
    expect(factory.calls, hasLength(1));
    expect(factory.calls.single.uri.path, '/ws/7');

    // 模拟 HttpClient 401 刷新失败回调（真实接线由 MyApp 激活）
    expect(HttpClient.onUnauthorized, isNotNull);
    HttpClient.onUnauthorized!();
    await tester.pumpAndSettle();

    // 直达登录页，不经过启动页/引导页
    expect(find.text('欢迎使用飞翼通'), findsOneWidget);
    expect(find.text('一键发布任务'), findsNothing);
    expect(find.text('飞翼通'), findsNothing, reason: '不应停留在启动页');

    // 登出后聊天 WS 已断开
    expect(chatService.isConnected, false);
  });

  testWidgets('4001 顶号：Snack提示「账号已在其他设备登录」且不自动重连', (tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    final stub = StubAdapter((options) async {
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
    final client = HttpClient(TokenStorage(prefs), adapter: stub);

    final kicked = FakeChatSocket()
      ..closeCode = ChatWebSocketService.supersededCloseCode
      ..closeReason = ChatWebSocketService.supersededCloseReason;
    final factory = ScriptedSocketFactory()..enqueueSocket(kicked);
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
    expect(find.byType(DispatchOrderListPage), findsOneWidget, reason: '已登录应落在首页');
    expect(chatService.isConnected, true);

    // 服务端以 4001 顶掉旧连接（新登录顶号语义）
    kicked.serverCloses();
    await tester.pumpAndSettle();

    expect(find.text('账号已在其他设备登录'), findsOneWidget);
    expect(chatService.isConnected, false);

    // 让 SnackBar 自动消退，清理定时器后确认仍不重连
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(factory.calls, hasLength(1), reason: '4001 后不自动重连（Q12=A）');
    // 用户仍保持登录态（仅聊天连接被顶）
    expect(find.byType(DispatchOrderListPage), findsOneWidget, reason: '已登录应落在首页');
  });
}
