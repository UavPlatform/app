// 聊天 WS 服务冒烟（P1-2 重连/心跳、P1-3 登出断开、t3 握手鉴权适配、t28 优化）。

import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/config/api_config.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  Future<TokenStorage> storageWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  test('握手携带 Bearer token，无本地地址时回落默认环境', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r',
    });
    final factory = ScriptedSocketFactory()..enqueueSocket(FakeChatSocket());
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));

      expect(factory.calls, hasLength(1));
      final call = factory.calls.single;
      expect(call.uri.path, '/ws/7');
      expect(call.uri.scheme, 'ws');
      expect(
        call.uri.host,
        Uri.parse(ApiConfig.defaultBaseUrl).host,
        reason: '未持久化 server_url 时应回落内置默认地址（P1-5）',
      );
      expect(call.headers['Authorization'], 'Bearer ${makeJwt(userId: 7)}');
    });
  });

  test('已持久化服务器地址优先生成 WS 地址', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 9),
      'jwt_refresh_token': 'r',
      'server_url': 'http://192.168.1.5:9000',
    });
    final factory = ScriptedSocketFactory()..enqueueSocket(FakeChatSocket());
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(9));
      async.elapse(const Duration(milliseconds: 10));

      final call = factory.calls.single;
      expect(call.uri.host, '192.168.1.5');
      expect(call.uri.port, 9000);
      expect(call.uri.path, '/ws/9');
    });
  });

  test('断线自动重连，重连成功后触发补拉（首连不补拉）', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r',
    });
    final first = FakeChatSocket();
    final second = FakeChatSocket();
    final factory = ScriptedSocketFactory()
      ..enqueueSocket(first)
      ..enqueueSocket(second);
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);
    final statuses = <ChatWebSocketStatus>[];
    service.status.listen(statuses.add);
    final resyncCount = <int>[];
    service.resync.listen((_) => resyncCount.add(1));

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(service.isConnected, true);
      expect(resyncCount, isEmpty, reason: '首次连接不属于断线补拉');

      first.serverCloses();
      async.elapse(const Duration(milliseconds: 10));
      expect(statuses.last, ChatWebSocketStatus.disconnected);
      expect(service.isConnected, false);

      // 退避 1s 后自动重连成功
      async.elapse(
        ChatWebSocketService.reconnectBaseDelay +
            const Duration(milliseconds: 10),
      );
      expect(factory.calls, hasLength(2));
      expect(service.isConnected, true);
      // 推送优先（t28①）：重连后先等 3s 静默窗，未收到下行才回落 REST 补拉
      expect(resyncCount, isEmpty, reason: '静默窗内不应立即补拉');
      async.elapse(
        ChatWebSocketService.resyncGracePeriod +
            const Duration(milliseconds: 10),
      );
      expect(resyncCount, hasLength(1), reason: '静默后应触发 REST 补拉兜底');
    });
  });

  test('重连后 3s 静默窗内收到下行（离线推送）则不回落 REST 补拉', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r',
    });
    final first = FakeChatSocket();
    final second = FakeChatSocket();
    final factory = ScriptedSocketFactory()
      ..enqueueSocket(first)
      ..enqueueSocket(second);
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);
    final resyncCount = <int>[];
    service.resync.listen((_) => resyncCount.add(1));

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));

      first.serverCloses();
      async.elapse(
        ChatWebSocketService.reconnectBaseDelay +
            const Duration(milliseconds: 10),
      );
      expect(service.isConnected, true);

      // 静默窗内服务端推送离线消息（isOffline 信封，msgId 幂等由上层处理）
      second.pushMessage({
        'msgId': 'offline-1',
        'sessionId': 5,
        'fromUserId': 8,
        'toUserId': 7,
        'content': '离线消息',
        'timestamp': 1789000000,
        'isOffline': true,
      });
      async.elapse(
        ChatWebSocketService.resyncGracePeriod * 2,
      );
      expect(resyncCount, isEmpty, reason: '已收到下行，不应回落 REST 补拉');
    });
  });

  test('静默窗期间登出则取消补拉信号', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r',
    });
    final first = FakeChatSocket();
    final second = FakeChatSocket();
    final factory = ScriptedSocketFactory()
      ..enqueueSocket(first)
      ..enqueueSocket(second);
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);
    final resyncCount = <int>[];
    service.resync.listen((_) => resyncCount.add(1));

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      first.serverCloses();
      async.elapse(
        ChatWebSocketService.reconnectBaseDelay +
            const Duration(milliseconds: 10),
      );
      expect(service.isConnected, true);

      // 重连成功后、静默窗结束前登出
      unawaited(service.disconnect());
      async.elapse(
        ChatWebSocketService.resyncGracePeriod * 2,
      );
      expect(resyncCount, isEmpty, reason: '登出后不应再补拉');
    });
  });

  test('重连退避按 1s,2s,4s,8s,16s,30s 封顶递增', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r',
    });

    FakeAsync().run((async) {
      final elapsedAtCall = <Duration>[];
      Future<ChatSocket> failingFactory(
        Uri uri,
        Map<String, String> headers,
      ) {
        elapsedAtCall.add(async.elapsed);
        return Future.error(StateError('server down'));
      }

      final service = ChatWebSocketService(storage, socketFactory: failingFactory);
      unawaited(service.ensureConnected(7));
      // 调用时点：0s,1s,3s,7s,15s,31s,61s,91s（8 次 → 7 个间隔）
      async.elapse(const Duration(seconds: 92));

      final gaps = <Duration>[
        for (var i = 1; i < elapsedAtCall.length; i++)
          elapsedAtCall[i] - elapsedAtCall[i - 1],
      ];
      expect(gaps.take(6).toList(), const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
        Duration(seconds: 30),
      ]);
      expect(gaps.length, greaterThanOrEqualTo(7));
      expect(gaps[6], const Duration(seconds: 30), reason: '退避 30s 封顶');
      service.dispose();
    });
  });

  test('心跳间隔写入协议层 pingInterval', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r',
    });
    final socket = FakeChatSocket();
    final factory = ScriptedSocketFactory()..enqueueSocket(socket);
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(socket.pingInterval, ChatWebSocketService.heartbeatInterval);
    });
  });

  test('登出断开：close 被调用且不再重连', () async {
    final storage = await storageWith({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r',
    });
    final socket = FakeChatSocket();
    final factory = ScriptedSocketFactory()..enqueueSocket(socket);
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(service.isConnected, true);

      unawaited(service.disconnect());
      async.elapse(const Duration(milliseconds: 10));

      expect(socket.closeCount, 1);
      expect(service.isConnected, false);

      // 登出后长时间运行也不应再发起连接
      async.elapse(const Duration(minutes: 5));
      expect(factory.calls, hasLength(1));
    });
  });

  test('无 token 时不发起连接（t3 握手必须携带 JWT）', () async {
    final storage = await storageWith(const {});
    final factory = ScriptedSocketFactory();
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);
    final statuses = <ChatWebSocketStatus>[];
    service.status.listen(statuses.add);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(factory.calls, isEmpty);
      expect(statuses.last, ChatWebSocketStatus.failed);
    });
  });

  group('握手 403 自愈（t28②）', () {
  Future<TokenStorage> storageWithToken() async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  test('握手 403 → 刷新成功 → 携新 token 立即重连', () async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = TokenStorage(prefs);
    final factory = ScriptedSocketFactory()
      ..enqueueError(WebSocketException('handshake rejected 403'))
      ..enqueueSocket(FakeChatSocket());
    var refreshCalls = 0;
    var sessionInvalidCalls = 0;
    final service = ChatWebSocketService(
      storage,
      socketFactory: factory.call,
      refreshSession: () async {
        refreshCalls += 1;
        // 模拟 HttpClient.refreshTokens：刷新成功并持久化新 token
        await prefs.setString('jwt_token', 'new-token');
        return TokenRefreshOutcome.refreshed;
      },
      onSessionInvalid: () => sessionInvalidCalls += 1,
    );
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      // 全链路（握手 403 → 刷新 → 携新 token 立即重连）均为微任务级，
      // 单次 elapse 即完成
      async.elapse(const Duration(milliseconds: 10));
      expect(refreshCalls, 1);
      expect(factory.calls, hasLength(2));
      expect(
        factory.calls[0].headers['Authorization'],
        'Bearer ${makeJwt(userId: 7)}',
      );
      expect(factory.calls[1].headers['Authorization'], 'Bearer new-token');
      expect(service.isConnected, true);
      expect(sessionInvalidCalls, 0);
    });
  });

  test('握手 403 → 刷新被拒 → 触发 onSessionInvalid 且不再重连', () async {
    final storage = await storageWithToken();
    final factory = ScriptedSocketFactory()
      ..enqueueError(WebSocketException('handshake rejected 403'));
    var sessionInvalidCalls = 0;
    final service = ChatWebSocketService(
      storage,
      socketFactory: factory.call,
      refreshSession: () async => TokenRefreshOutcome.rejected,
      onSessionInvalid: () => sessionInvalidCalls += 1,
    );
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(sessionInvalidCalls, 1);
      expect(factory.calls, hasLength(1));

      // 会话失效后长时间运行不再重连
      async.elapse(const Duration(minutes: 5));
      expect(factory.calls, hasLength(1));
    });
  });

  test('刷新后仍被 403 拒 → 触发 onSessionInvalid（防刷新风暴）', () async {
    final storage = await storageWithToken();
    final factory = ScriptedSocketFactory()
      ..enqueueError(WebSocketException('403'))
      ..enqueueError(WebSocketException('403'));
    var refreshCalls = 0;
    var sessionInvalidCalls = 0;
    final service = ChatWebSocketService(
      storage,
      socketFactory: factory.call,
      refreshSession: () async {
        refreshCalls += 1;
        return TokenRefreshOutcome.refreshed;
      },
      onSessionInvalid: () => sessionInvalidCalls += 1,
    );
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 20));
      expect(refreshCalls, 1);
      expect(factory.calls, hasLength(2));
      expect(sessionInvalidCalls, 1, reason: '新 token 仍被拒，不应无限刷新');
      async.elapse(const Duration(minutes: 5));
      expect(factory.calls, hasLength(2));
    });
  });

  test('网络故障（SocketException）不触发刷新，维持退避', () async {
    final storage = await storageWithToken();
    final factory = ScriptedSocketFactory()
      ..enqueueError(const SocketException('network down'))
      ..enqueueSocket(FakeChatSocket());
    var refreshCalls = 0;
    final service = ChatWebSocketService(
      storage,
      socketFactory: factory.call,
      refreshSession: () async {
        refreshCalls += 1;
        return TokenRefreshOutcome.refreshed;
      },
    );
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(refreshCalls, 0, reason: '网络故障不是鉴权问题，不应刷新');

      async.elapse(
        ChatWebSocketService.reconnectBaseDelay +
            const Duration(milliseconds: 10),
      );
      expect(refreshCalls, 0);
      expect(factory.calls, hasLength(2));
      expect(service.isConnected, true);
    });
  });

  test('未注入 refreshSession 时 403 退回普通退避（向后兼容）', () async {
    final storage = await storageWithToken();
    final factory = ScriptedSocketFactory()
      ..enqueueError(WebSocketException('403'))
      ..enqueueSocket(FakeChatSocket());
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(factory.calls, hasLength(1));

      async.elapse(
        ChatWebSocketService.reconnectBaseDelay +
            const Duration(milliseconds: 10),
      );
      expect(factory.calls, hasLength(2));
      expect(service.isConnected, true);
    });
  });
});

group('4001 顶号分支（t28③，Q12=A 强制单设备在线）', () {
  Future<TokenStorage> storageWithToken() async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'jwt_refresh_token': 'r-1',
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(prefs);
  }

  test('收到 4001 → 上抛 superseded 并停止自动重连', () async {
    final storage = await storageWithToken();
    final socket = FakeChatSocket()
      ..closeCode = ChatWebSocketService.supersededCloseCode
      ..closeReason = ChatWebSocketService.supersededCloseReason;
    final factory = ScriptedSocketFactory()..enqueueSocket(socket);
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);
    final statuses = <ChatWebSocketStatus>[];
    service.status.listen(statuses.add);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(service.isConnected, true);

      socket.serverCloses();
      async.elapse(const Duration(milliseconds: 10));
      expect(statuses.last, ChatWebSocketStatus.superseded);
      expect(service.isConnected, false);

      async.elapse(const Duration(minutes: 5));
      expect(factory.calls, hasLength(1), reason: '顶号后不自动重连');
    });
  });

  test('未知关闭码维持既有退避', () async {
    final storage = await storageWithToken();
    final first = FakeChatSocket(); // 无关闭码（未知）
    final factory = ScriptedSocketFactory()
      ..enqueueSocket(first)
      ..enqueueSocket(FakeChatSocket());
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      first.serverCloses();
      async.elapse(
        ChatWebSocketService.reconnectBaseDelay +
            const Duration(milliseconds: 10),
      );
      expect(factory.calls, hasLength(2), reason: '非 4001 走既有退避重连');
      expect(service.isConnected, true);
    });
  });

  test('superseded 后手动 ensureConnected 可重连', () async {
    final storage = await storageWithToken();
    final kicked = FakeChatSocket()
      ..closeCode = ChatWebSocketService.supersededCloseCode;
    final reconnected = FakeChatSocket();
    final factory = ScriptedSocketFactory()
      ..enqueueSocket(kicked)
      ..enqueueSocket(reconnected);
    final service = ChatWebSocketService(storage, socketFactory: factory.call);
    addTearDown(service.dispose);
    final statuses = <ChatWebSocketStatus>[];
    service.status.listen(statuses.add);

    FakeAsync().run((async) {
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      kicked.serverCloses();
      async.elapse(const Duration(milliseconds: 10));
      expect(statuses.last, ChatWebSocketStatus.superseded);

      // 用户重新进入消息页 → 手动重连
      unawaited(service.ensureConnected(7));
      async.elapse(const Duration(milliseconds: 10));
      expect(factory.calls, hasLength(2));
      expect(service.isConnected, true);
    });
    });
  });
}
