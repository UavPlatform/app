// TASK-APP-006：注册通道回归（REQ-APP-001）。
//
// 覆盖登录页两个注册入口：
//   1. 点「用户注册」进入 RegisterPage，提交 /user/register 成功后回登录页；
//   2. 点「飞手注册」进入 RiderRegisterPage，提交 /rider/register 成功后回登录页。

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/main.dart';
import 'package:uav_pilot_app/pages/auth/login_page.dart';
import 'package:uav_pilot_app/pages/auth/register_page.dart';
import 'package:uav_pilot_app/pages/auth/rider_register_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

/// 未登录启动真实 App：桩 HTTP + 假 WS。
Future<StubAdapter> pumpLoggedOutApp(
  WidgetTester tester, {
  Future<ResponseBody> Function(RequestOptions options)? handler,
}) async {
  SharedPreferences.setMockInitialValues({'server_url': 'http://stub.local:8081'});
  final prefs = await SharedPreferences.getInstance();
  final stub = StubAdapter(
    handler ??
        (options) async => jsonResponse(200, {'success': false, 'message': 'stub'}),
  );
  final client = HttpClient(TokenStorage(prefs), adapter: stub);

  final factory = ScriptedSocketFactory();
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

  // 启动页 2s 后进入引导页，再「跳过」到登录页（真实用户路径）。
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  await tester.tap(find.text('跳过'));
  await tester.pumpAndSettle();
  expect(find.byType(LoginPage), findsOneWidget);
  return stub;
}

void main() {
  testWidgets('用户注册入口：点击进入注册页', (tester) async {
    final stub = await pumpLoggedOutApp(tester);

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('用户注册'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget,
        reason: '点击「用户注册」应导航到注册页');
    expect(stub.requests, isEmpty, reason: '仅导航不应发请求');
  });

  testWidgets('飞手注册入口：点击进入飞手注册页', (tester) async {
    final stub = await pumpLoggedOutApp(tester);

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('飞手注册'));
    await tester.pumpAndSettle();

    expect(find.byType(RiderRegisterPage), findsOneWidget,
        reason: '点击「飞手注册」应导航到飞手注册页');
    expect(stub.requests, isEmpty, reason: '仅导航不应发请求');
  });

  testWidgets('用户注册提交：POST /user/register 成功后回登录页', (tester) async {
    final stub = await pumpLoggedOutApp(
      tester,
      handler: (options) async {
        if (options.uri.path == '/user/register') {
          expect(options.data, {'userName': 'alice', 'password': 'secret12'});
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'message': '操作成功',
            'data': {'id': 1, 'userName': 'alice'},
          });
        }
        return jsonResponse(200, {'success': false, 'message': 'unexpected'});
      },
    );

    await tester.tap(find.text('用户注册'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'alice');
    await tester.enterText(fields.at(1), 'secret12');
    await tester.enterText(fields.at(2), 'secret12');
    await tester.tap(find.text('注 册'));
    await tester.pumpAndSettle();

    expect(
      stub.requests.map((r) => r.uri.path),
      contains('/user/register'),
      reason: '提交应调用 POST /user/register',
    );
    expect(find.text('注册成功，请登录'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget,
        reason: '注册成功后应回到登录页');
  });

  testWidgets('飞手注册提交：POST /rider/register 成功后回登录页', (tester) async {
    final stub = await pumpLoggedOutApp(
      tester,
      handler: (options) async {
        if (options.uri.path == '/rider/register') {
          expect(options.data, {
            'userName': 'bob',
            'password': 'secret12',
          });
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'message': '飞手注册成功',
            'data': {'token': 't', 'refreshToken': 'r'},
          });
        }
        return jsonResponse(200, {'success': false, 'message': 'unexpected'});
      },
    );

    await tester.tap(find.text('飞手注册'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'bob');
    await tester.enterText(fields.at(1), 'secret12');
    await tester.enterText(fields.at(2), 'secret12');
    expect(fields, findsNWidgets(3), reason: '飞手注册不再手填无人机编号');
    await tester.tap(find.text('注册飞手'));
    await tester.pumpAndSettle();

    expect(
      stub.requests.map((r) => r.uri.path),
      contains('/rider/register'),
      reason: '提交应调用 POST /rider/register',
    );
    expect(find.byType(RiderRegisterPage), findsNothing,
        reason: '飞手注册成功后应离开注册页');
  });

  // 用户实测症状：401 强制登出（sessionExpired）后停在登录页，点
  // 「用户注册」「飞手注册」毫无反应、始终留在登录页（TASK-APP-006 根因）。
  testWidgets('会话过期强制登出后，两个注册入口仍可进入注册页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    final stub = StubAdapter(
      (options) async => jsonResponse(200, {'success': false, 'message': 'stub'}),
    );
    final client = HttpClient(TokenStorage(prefs), adapter: stub);
    final factory = ScriptedSocketFactory()
      ..enqueueSocket(FakeChatSocket())
      ..enqueueSocket(FakeChatSocket());
    final chatService = ChatWebSocketService(
      TokenStorage(prefs),
      socketFactory: factory.call,
    );
    addTearDown(() => HttpClient.onUnauthorized = null);

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

    // 模拟 401 刷新失败强制登出 → 直达登录页（sessionExpired = true）
    expect(HttpClient.onUnauthorized, isNotNull);
    HttpClient.onUnauthorized!();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('用户注册'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterPage), findsOneWidget,
        reason: 'sessionExpired 态下点「用户注册」应进入注册页（修复前被重定向回登录页）');

    await tester.tap(find.text('返回登录'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('飞手注册'));
    await tester.pumpAndSettle();
    expect(find.byType(RiderRegisterPage), findsOneWidget,
        reason: 'sessionExpired 态下点「飞手注册」应进入飞手注册页（修复前被重定向回登录页）');
  });
}
