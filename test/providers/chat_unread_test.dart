// 未读数深修测试（t50：角标=会话未读求和、进入会话清零、增减联动）。

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

  testWidgets('未读角标 = 会话未读求和（2+3=5）', (tester) async {
    debugPrint('M1: start');
    final overrides = await buildOverrides();
    debugPrint('M2: overrides built');
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MaterialApp(home: SizedBox())),
    );
    debugPrint('M3: pumped');
    await seedSessions(tester);
    debugPrint('M4: seeded');

    expect(containerOf(tester).read(totalUnreadCountProvider), 5);
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
    expect(container.read(totalUnreadCountProvider), 5);

    await tester.runAsync(() async {
      await container.read(sessionListProvider.notifier).markSessionRead(22);
    });
    await tester.pump(const Duration(milliseconds: 20));

    expect(readCalls, [22], reason: '显式已读端点被调用（t49 契约）');
    final sessions = container.read(sessionListProvider).sessions;
    expect(sessions.firstWhere((s) => s.id == 22).unreadCount, 0,
        reason: '已读会话本地未读清零');
    expect(sessions.firstWhere((s) => s.id == 11).unreadCount, 2,
        reason: '其他会话未读不受影响');
    expect(container.read(totalUnreadCountProvider), 2, reason: '角标随之 -3');
  });

  testWidgets('角标随实时消息 +1（会话状态变化驱动派生角标）', (tester) async {
    final overrides = await buildOverrides();
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const MaterialApp(home: SizedBox())),
    );
    await seedSessions(tester);
    final container = containerOf(tester);
    expect(container.read(totalUnreadCountProvider), 5);

    final notifier = container.read(sessionListProvider.notifier);
    notifier.state = notifier.state.copyWith(
      sessions: notifier.state.sessions
          .map((s) => s.id == 11 ? s.copyWith(unreadCount: s.unreadCount + 1) : s)
          .toList(),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(container.read(totalUnreadCountProvider), 6, reason: '实时收信角标 +1');
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
    expect(container.read(totalUnreadCountProvider), 9);

    await tester.runAsync(() async {
      await notifier.markSessionRead(99);
    });
    await tester.pump(const Duration(milliseconds: 20));

    final system = container
        .read(sessionListProvider)
        .sessions
        .firstWhere((s) => s.type == 2);
    expect(system.unreadCount, 0, reason: '系统会话红点清零（t33 联动）');
    expect(container.read(totalUnreadCountProvider), 5, reason: '系统会话清零后仅剩聊天会话未读');
  });
}
