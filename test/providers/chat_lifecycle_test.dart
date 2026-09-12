// 认证驱动的聊天实时链路生命周期（P1-3 登出断开、P1-4 401 兜底登出、t28 403 自愈接线）。

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });

  Future<(ProviderContainer, ScriptedSocketFactory)> buildContainer({
    required Map<String, Object> prefsValues,
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    final factory = ScriptedSocketFactory()
      ..enqueueSocket(FakeChatSocket())
      ..enqueueSocket(FakeChatSocket());
    final service = ChatWebSocketService(
      TokenStorage(prefs),
      socketFactory: factory.call,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        chatWebSocketServiceProvider.overrideWithValue(service),
      ],
    );
    return (container, factory);
  }

  test('登录态冷启动自动建立 WS；登出后断开且不再重连', () async {
    final (container, factory) = await buildContainer(prefsValues: {
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    addTearDown(container.dispose);

    expect(container.read(authProvider).status, AuthStatus.authenticated);

    // MyApp build 时 watch 激活生命周期
    container.read(chatRealtimeLifecycleProvider);
    await pumpEventQueue();

    expect(factory.calls, hasLength(1));
    expect(factory.calls.single.uri.path, '/ws/7');
    expect(container.read(chatWebSocketServiceProvider).isConnected, true);

    await container.read(authProvider.notifier).logout();
    await pumpEventQueue();

    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    expect(
      container.read(chatWebSocketServiceProvider).isConnected,
      false,
      reason: '登出后 WS 应关闭（P1-3）',
    );
    expect(factory.calls, hasLength(1), reason: '登出后不应重连');
  });

  test('401 兜底回调触发本地登出并断开 WS', () async {
    final (container, factory) = await buildContainer(prefsValues: {
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    addTearDown(container.dispose);

    container.read(chatRealtimeLifecycleProvider);
    container.read(unauthorizedSessionGuardProvider);
    await pumpEventQueue();
    expect(container.read(chatWebSocketServiceProvider).isConnected, true);

    // 模拟 HttpClient 在 401 刷新失败时触发全局回调
    expect(HttpClient.onUnauthorized, isNotNull);
    HttpClient.onUnauthorized!();
    await pumpEventQueue();

    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    expect(
      container.read(authProvider).sessionExpired,
      true,
      reason: '强制登出应带 sessionExpired 标记供路由直达登录页',
    );
    expect(container.read(chatWebSocketServiceProvider).isConnected, false);
    expect(factory.calls, hasLength(1), reason: '强制登出后不应重连');
  });

  test('WS 握手 403 → 刷新被拒 → 走 sessionExpired 登出链（t28② 接线）', () async {
    // refreshToken 缺失：refreshTokens() 必然 rejected（会话无法自愈）
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    final factory = ScriptedSocketFactory()
      ..enqueueError(WebSocketException('handshake rejected 403'));
    // 与 chatWebSocketServiceProvider 生产接线相同的回调表达式
    // （工厂改为测试注入，其余一致）：
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);
    final service = ChatWebSocketService(
      TokenStorage(prefs),
      socketFactory: factory.call,
      refreshSession: () => container.read(httpClientProvider).refreshTokens(),
      onSessionInvalid: () => unawaited(
        container.read(authProvider.notifier).logout(sessionExpired: true),
      ),
    );

    container.read(chatRealtimeLifecycleProvider);
    unawaited(service.ensureConnected(7));
    await pumpEventQueue();

    // 握手 403 → refreshTokens（refreshToken 缺失）= rejected → 登出链
    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    expect(container.read(authProvider).sessionExpired, true);
    expect(service.isConnected, false);
    expect(factory.calls, hasLength(1), reason: '登出后不再重连');
  });
}
