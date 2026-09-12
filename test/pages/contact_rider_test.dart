// 用户侧「联系飞手」入口测试（t34：入口显隐、创建会话跳转、消息互通）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/chat/chat_detail_page.dart';
import 'package:uav_pilot_app/pages/orders/order_detail_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  Map<String, dynamic> taskJson({
    String taskStatus = 'IN_PROGRESS',
    int? riderId = 8,
    String riderName = '飞手甲',
    String orderStatus = 'PAID',
  }) {
    return {
      'id': 1,
      'taskNum': 'T20260912-001',
      'taskName': '航拍任务',
      'userId': 7,
      'taskType': 'AERIAL_PHOTO',
      'taskStatus': taskStatus,
      'orderNum': 'ORD-1',
      'totalAmount': 128.5,
      'orderStatus': orderStatus,
      'riderId': riderId,
      'riderName': riderName,
      'createTime': '2026-09-12T10:00:00',
      'updateTime': '2026-09-12T10:00:00',
    };
  }

  Future<List<Override>> buildOverrides(
    StubAdapter adapter, {
    String taskNum = 'T20260912-001',
  }) async {
    SharedPreferences.setMockInitialValues({
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

  StubAdapter taskDetailAdapter(Map<String, dynamic> task) {
    return StubAdapter((options) async {
      if (options.uri.path == '/task/detail') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': task});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  testWidgets('已接单状态显示「联系飞手」入口', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          taskDetailAdapter(taskJson()),
        ),
        child: const MaterialApp(home: OrderDetailPage(taskNum: 'T20260912-001')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('接单飞手'), findsOneWidget);
    expect(find.text('飞手甲'), findsOneWidget);
    expect(find.text('联系飞手'), findsOneWidget);
  });

  testWidgets('未接单（待支付/无飞手）不显示「联系飞手」入口', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          taskDetailAdapter(
            taskJson(
              taskStatus: 'IDLE',
              riderId: null,
              riderName: '',
              orderStatus: 'PENDING',
            ),
          ),
        ),
        child: const MaterialApp(home: OrderDetailPage(taskNum: 'T20260912-001')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('联系飞手'), findsNothing, reason: '尚无飞手接单，无沟通对象');
    expect(find.text('去支付'), findsOneWidget);
  });

  testWidgets('点击「联系飞手」创建直连会话并跳转聊天页，双向消息可见',
      (tester) async {
    var messageLoad = 0;
    var createCall = 0;
    var sendCall = 0;
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': taskJson(),
        });
      }
      if (path == '/chat/session/create') {
        createCall += 1;
        expect(options.uri.path, '/chat/session/create');
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'id': 55,
            'name': '飞手甲',
            'type': 0,
            'userIds': [7, 8],
            'createTime': 1789000000,
            'unreadCount': 0,
          },
        });
      }
      if (path == '/chat/session/list') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': [],
        });
      }
      if (path == '/chat/Message/messages/55') {
        messageLoad += 1;
        final messages = [
          {
            'msgId': 'm1',
            'sessionId': 55,
            'fromUserId': 8,
            'toUserId': 7,
            'content': 'ignored',
            'payload': {'text': '你好，我是飞手'},
            'timestamp': 1789000100,
          },
          if (messageLoad >= 2)
            {
              'msgId': 'm2',
              'sessionId': 55,
              'fromUserId': 7,
              'toUserId': 8,
              'content': 'ignored',
              'payload': {'text': '收到，请准时到达'},
              'timestamp': 1789000200,
            },
        ];
        return jsonResponse(200, {'success': true, 'code': 200, 'data': messages});
      }
      if (path == '/chat/Message/send') {
        sendCall += 1;
        return jsonResponse(200, {'success': true, 'code': 200});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    // 跳转经由 go_router 路由 /chat/:sessionId，测试中注入等价路由表
    final router = GoRouter(
      initialLocation: '/task/T20260912-001',
      routes: [
        GoRoute(
          path: '/task/:taskNum',
          builder: (_, state) => OrderDetailPage(
            taskNum: state.pathParameters['taskNum']!,
          ),
        ),
        GoRoute(
          path: '/chat/:sessionId',
          builder: (_, state) => ChatDetailPage(
            sessionId: int.parse(state.pathParameters['sessionId']!),
            sessionName: state.uri.queryParameters['name'],
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 联系飞手 → 创建直连会话 → 跳转聊天详情页
    await tester.tap(find.text('联系飞手'));
    await tester.pumpAndSettle();

    expect(createCall, 1);
    expect(find.text('飞手甲'), findsWidgets, reason: '聊天页标题为飞手名称');
    // 飞手→用户方向的历史消息可见（WS 下行同构，t28 已覆盖实时分支）
    expect(find.text('你好，我是飞手'), findsOneWidget);

    // 用户→飞手发送消息
    await tester.enterText(find.byType(TextField), '收到，请准时到达');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(sendCall, 1);
    expect(find.text('收到，请准时到达'), findsOneWidget, reason: '发送后消息列表刷新可见');
  });
}
