// 未读数深修测试（t50：会话未读=按单红点数据源、进入会话清零、增减联动）。
// APP-003 按单红点改造后不再有全局未读角标（totalUnreadCountProvider 已删）：
// 这里断言会话级未读的保留/清零/增减——订单列表红点由 orderUnreadProvider
// 按 taskNum 聚合（UI 见 routes/user_shell_route_test）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/session_vo.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

ProviderContainer containerOf(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(SizedBox).first),
  );
}

void main() {
  var readCalls = <int>[];

  StubAdapter sessionAdapter() {
    return StubAdapter((options) async {
      if (options.uri.path == '/chat/session/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': [
            {
              'id': 11,
              'name': '飞手甲',
              'type': 0,
              'userIds': [7, 8],
              'unreadCount': 2,
              'lastMessage': '早',
              'lastMessageTime': 1789000100,
              'createTime': 1789000000,
            },
            {
              'id': 22,
              'name': '飞手乙',
              'type': 0,
              'userIds': [7, 9],
              'unreadCount': 3,
              'lastMessage': '好',
              'lastMessageTime': 1789000200,
              'createTime': 1789000000,
            },
          ],
        });
      }
      if (options.uri.path == '/chat/Message/read') {
        readCalls.add(int.parse(options.uri.queryParameters['sessionId']!));
        return jsonResponse(200, {'success': true, 'code': 200});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  Future<List<Override>> buildOverrides() async {
    readCalls = [];
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      httpClientProvider.overrideWithValue(
        HttpClient(TokenStorage(prefs), adapter: sessionAdapter()),
      ),
    ];
  }

  Future<void> seedSessions(WidgetTester tester) async {
    final container = containerOf(tester);
    await tester.runAsync(() async {
      await container.read(sessionListProvider.notifier).load();
    });
    await tester.pump();
  }

  testWidgets('会话未读按会话保留（按单红点数据源 2/3）', (tester) async {
    debugPrint('M1: start');
    final overrides = await buildOverrides();
    debugPrint('M2: overrides built');
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MaterialApp(home: SizedBox())),
    );
    debugPrint('M3: pumped');
    await seedSessions(tester);
    debugPrint('M4: seeded');

    final sessions = containerOf(tester).read(sessionListProvider).sessions;
    expect(sessions.firstWhere((s) => s.id == 11).unreadCount, 2,
        reason: '会话 11 未读保留给其归属订单');
    expect(sessions.firstWhere((s) => s.id == 22).unreadCount, 3,
        reason: '会话 22 未读保留给其归属订单');
    debugPrint('M5: asserted');
  });

  testWidgets('markSessionRead：POST /chat/Message/read 且对应会话本地清零',
      (tester) async {
    final overrides = await buildOverrides();
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MaterialApp(home: SizedBox())),
    );
    await seedSessions(tester);
    final container = containerOf(tester);
    final seeded = container.read(sessionListProvider).sessions;
    expect(seeded.firstWhere((s) => s.id == 11).unreadCount, 2);
    expect(seeded.firstWhere((s) => s.id == 22).unreadCount, 3);

    await tester.runAsync(() async {
      await container.read(sessionListProvider.notifier).markSessionRead(22);
    });
    await tester.pump(const Duration(milliseconds: 20));

    expect(readCalls, [22], reason: '显式已读端点被调用（t49 契约）');
    final sessions = container.read(sessionListProvider).sessions;
    expect(sessions.firstWhere((s) => s.id == 22).unreadCount, 0,
        reason: '已读会话本地未读清零（该订单红点随之消退）');
    expect(sessions.firstWhere((s) => s.id == 11).unreadCount, 2,
        reason: '其他会话未读不受影响（红点按单隔离）');
  });

  testWidgets('实时消息驱动会话未读 +1（按单红点随之刷新）', (tester) async {
    final overrides = await buildOverrides();
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MaterialApp(home: SizedBox())),
    );
    await seedSessions(tester);
    final container = containerOf(tester);
    expect(
      container.read(sessionListProvider).sessions
          .firstWhere((s) => s.id == 11).unreadCount,
      2,
    );

    final notifier = container.read(sessionListProvider.notifier);
    notifier.state = notifier.state.copyWith(
      sessions: notifier.state.sessions
          .map((s) => s.id == 11 ? s.copyWith(unreadCount: s.unreadCount + 1) : s)
          .toList(),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      container.read(sessionListProvider).sessions
          .firstWhere((s) => s.id == 11).unreadCount,
      3,
      reason: '实时收信只加到对应会话（红点按单 +1）',
    );
  });

  testWidgets('系统会话红点联动清零', (tester) async {
    final overrides = await buildOverrides();
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MaterialApp(home: SizedBox())),
    );
    await seedSessions(tester);
    final container = containerOf(tester);
    final notifier = container.read(sessionListProvider.notifier);
    notifier.state = notifier.state.copyWith(
      sessions: [
        ...notifier.state.sessions,
        SessionVo(
          id: 99,
          name: '系统通知',
          type: 2,
          userIds: const [7],
          unreadCount: 4,
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 20));
    expect(
      container.read(sessionListProvider).sessions
          .firstWhere((s) => s.id == 99).unreadCount,
      4,
      reason: '系统会话未读独立计入',
    );

    await tester.runAsync(() async {
      await notifier.markSessionRead(99);
    });
    await tester.pump(const Duration(milliseconds: 20));

    final after = container.read(sessionListProvider).sessions;
    final system = after.firstWhere((s) => s.type == 2);
    expect(system.unreadCount, 0, reason: '系统会话红点清零（t33 联动）');
    expect(after.firstWhere((s) => s.id == 11).unreadCount, 2,
        reason: '聊天会话未读不受系统会话已读影响');
    expect(after.firstWhere((s) => s.id == 22).unreadCount, 3,
        reason: '聊天会话未读不受系统会话已读影响');
  });
}
