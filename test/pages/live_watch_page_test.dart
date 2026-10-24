// 直播观看页测试（t38：凭证拉取、生命周期、退出不误停推流、结束态）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/live/live_watch_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/live_player.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  final credentialJson = {
    'roomId': 'drone_UAV-001',
    'userId': '7',
    'userSig': 'sig-abc',
    'privateMapKey': 'test-legacy-room-ticket',
    'sdkAppId': 1400000000,
    'wsUrl': 'ws://stub.local:8081/ws/drone/UAV-001',
    'liveState': 'RUNNING',
    'ackConfirmed': true,
  };

  Future<List<Override>> buildOverrides({
    required StubAdapter adapter,
    FakeTrtcEngine? engine,
  }) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      httpClientProvider.overrideWithValue(
        HttpClient(TokenStorage(prefs), adapter: adapter),
      ),
      liveEngineProvider.overrideWithValue(engine ?? FakeTrtcEngine()),
    ];
  }

  StubAdapter credentialAdapter(Map<String, dynamic> credential) {
    return StubAdapter((options) async {
      if (options.uri.path == '/live/get') {
        expect(options.uri.queryParameters['deviceId'], 'UAV-001');
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': credential,
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  testWidgets('凭证拉取进房：引擎以响应值进房（不自报身份）', (tester) async {
    final engine = FakeTrtcEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          adapter: credentialAdapter(credentialJson),
          engine: engine,
        ),
        child: const MaterialApp(
          home: LiveWatchPage(deviceId: 'UAV-001', useRealVideoView: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(engine.entered, hasLength(1));
    expect(engine.entered.single.strRoomId, 'drone_UAV-001');
    expect(
      engine.entered.single.userId,
      '7',
      reason: 'userId 使用 /live/get 响应值',
    );
    expect(engine.entered.single.userSig, 'sig-abc');
    expect(engine.entered.single.privateMapKey, 'test-legacy-room-ticket');
    expect(engine.entered.single.sdkAppId, 1400000000);
    expect(find.byKey(const Key('live-video-placeholder')), findsOneWidget);
    expect(find.text('作业直播进行中'), findsOneWidget);

    // 显式卸载并冲洗（dispose 的 leave 调用为一次性）
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 5));
    await tester.pump();
  });

  testWidgets('主播停流 → 展示直播已结束并释放播放资源', (tester) async {
    final engine = FakeTrtcEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          adapter: credentialAdapter(credentialJson),
          engine: engine,
        ),
        child: const MaterialApp(
          home: LiveWatchPage(deviceId: 'UAV-001', useRealVideoView: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(engine.exitCalls, 0);

    // 主播停流（远端视频不可用）
    engine.emitRemoteVideoUnavailable();
    await tester.pumpAndSettle();

    expect(find.text('直播已结束'), findsOneWidget);
    expect(engine.exitCalls, 1, reason: '结束时释放播放资源');
    expect(engine.detachCalls, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 5));
    await tester.pump();
  });

  testWidgets('用户关闭页面 → 释放播放资源且不调 /live/close', (tester) async {
    var closeCalled = false;
    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/live/get') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': credentialJson,
        });
      }
      if (options.uri.path == '/live/close') {
        closeCalled = true;
        return jsonResponse(200, {'success': true});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
    final engine = FakeTrtcEngine();

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter: adapter, engine: engine),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LiveWatchPage(
                      deviceId: 'UAV-001',
                      useRealVideoView: false,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(LiveWatchPage), findsOneWidget);
    expect(engine.entered, hasLength(1));

    // 用户点击关闭 → 释放资源
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(engine.exitCalls, 1, reason: '退出释放播放资源');
    expect(engine.detachCalls, 1);
    expect(find.text('open'), findsOneWidget, reason: '已返回上一页');
    expect(closeCalled, false, reason: '用户退出不调 /live/close，不误停推流（t38④）');
  });

  testWidgets('直播未运行 → 提示不进房', (tester) async {
    final engine = FakeTrtcEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          adapter: credentialAdapter({
            ...credentialJson,
            'liveState': 'IDLE',
            'ackConfirmed': false,
          }),
          engine: engine,
        ),
        child: const MaterialApp(
          home: LiveWatchPage(deviceId: 'UAV-001', useRealVideoView: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('直播当前未在运行'), findsOneWidget);
    expect(engine.entered, isEmpty, reason: '未运行不进房');
  });
}
