// 系统通知聚合视图测试（t33②：入口接通后聚合展示系统消息，APP P3-4 空壳消除）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/messages/system_messages_view.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  Future<List<Override>> buildOverrides(StubAdapter adapter) async {
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
    ];
  }

  testWidgets('聚合展示系统会话中的系统消息卡片（过滤普通消息）', (tester) async {
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/chat/session/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': [
            {
              'id': 99,
              'name': '系统通知',
              'type': 2,
              'userIds': [7],
              'createTime': 1789000000,
              'unreadCount': 2,
            },
            {
              'id': 55,
              'name': '飞手甲',
              'type': 0,
              'userIds': [7, 8],
              'createTime': 1789000000,
              'unreadCount': 0,
            },
          ],
        });
      }
      if (path == '/chat/Message/messages/99') {
        expect(options.uri.queryParameters['sessionId'], isNull);
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': [
            {
              'msgId': 'sys-1',
              'sessionId': 99,
              'msgType': 2,
              'fromUserId': 0,
              'timestamp': DateTime(2026, 9, 12, 9, 48).millisecondsSinceEpoch,
              'payload': {
                'type': 'ORDER',
                'name': 'ORDER_PAID',
                'text': '您的任务已支付成功，等待飞手接单',
              },
            },
            {
              'msgId': 'sys-2',
              'sessionId': 99,
              'msgType': 1,
              'fromUserId': 0,
              'timestamp': 1789000200000,
              'payload': {
                'type': 'NOTICE',
                'name': 'TASK_ACCEPTED',
                'text': '您的任务已被飞手接单',
              },
            },
            {
              'msgId': 'chat-1',
              'sessionId': 99,
              'msgType': 0,
              'fromUserId': 8,
              'timestamp': 1789000300000,
              'payload': {'text': '不应出现的普通消息'},
            },
          ],
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: SystemMessagesView()),
      ),
    );
    await tester.pumpAndSettle();

    // 系统卡片渲染（按事件名），普通消息被过滤
    expect(find.text('支付成功'), findsOneWidget);
    expect(find.text('您的任务已支付成功，等待飞手接单'), findsOneWidget);
    expect(find.text('任务已被接单'), findsOneWidget);
    expect(find.textContaining('不应出现的普通消息'), findsNothing);
  });

  testWidgets('已知 sessionId 时直接拉取系统会话消息', (tester) async {
    var detailCalled = false;
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/chat/Message/messages/99') {
        detailCalled = true;
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': [
            {
              'msgId': 'sys-1',
              'sessionId': 99,
              'msgType': 1,
              'fromUserId': 0,
              'timestamp': DateTime(2026, 9, 12, 9, 48).millisecondsSinceEpoch,
              'payload': {
                'type': 'NOTICE',
                'name': 'TASK_ACCEPTED',
                'text': '您的任务已被飞手接单',
              },
            },
          ],
        });
      }
      if (path == '/chat/session/list') {
        throw StateError('已知 sessionId 时不应再查会话列表');
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: SystemMessagesView(sessionId: 99)),
      ),
    );
    await tester.pumpAndSettle();

    expect(detailCalled, true);
    expect(find.text('任务已被接单'), findsOneWidget);
  });

  testWidgets('系统会话尚未创建（无通知）时展示空态', (tester) async {
    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/chat/session/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': [
            {
              'id': 55,
              'name': '飞手甲',
              'type': 0,
              'userIds': [7, 8],
              'createTime': 1789000000,
              'unreadCount': 0,
            },
          ],
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: SystemMessagesView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无系统消息'), findsOneWidget);
    expect(find.textContaining('任务状态变更通知'), findsOneWidget);
  });
}
