// 订单详情 = 撮合中心（TASK-APP-003 / ADR-0003）：
//   1. 应征列表渲染（飞手 + 机型 + 载重 + 系统报价只读 + 应征时间 + 会话未读）；
//   2. 空状态「等待飞手接单」，非撮合阶段且无应征时隐藏；
//   3. 点击应征项进入订单内聊天（已有会话直达 / chat/session/create 带 taskNum + applicationId）；
//   4. 红线：页面不存在任何价格输入控件。

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
  const taskNum = 'T20260926-001';

  Map<String, dynamic> taskJson({
    String matchStatus = 'SEEKING_RIDER',
    String? actionHint = '等待飞手应征，选定后下单支付',
  }) {
    return {
      'id': 1,
      'taskNum': taskNum,
      'taskName': '山顶基站建材吊运',
      'userId': 7,
      'taskType': 'TRANSPORT',
      'taskStatus': 'IDLE',
      'matchStatus': matchStatus,
      'actionHint': actionHint,
      'createTime': '2026-09-26T09:00:00',
      'updateTime': '2026-09-26T09:30:00',
    };
  }

  final applications = <Map<String, dynamic>>[
    {
      'applicationId': 11,
      'taskNum': taskNum,
      'riderId': 8,
      'riderName': '飞手甲',
      'aircraftModelId': 3,
      'aircraftModelName': 'DJI FlyCart 30',
      'modelCode': 'FC30',
      'maxPayloadKg': 30,
      'quotedAmount': 980,
      'appliedAt': '2026-09-26T10:20:00',
      'matchStatus': 'SEEKING_RIDER',
      'status': 'ACTIVE',
    },
    {
      'applicationId': 12,
      'taskNum': taskNum,
      'riderId': 9,
      'riderName': '飞手乙',
      'aircraftModelId': 4,
      'aircraftModelName': 'DJI Matrice 350 RTK',
      'modelCode': 'M350RTK',
      'maxPayloadKg': 2.7,
      'quotedAmount': 1200.5,
      'appliedAt': '2026-09-26T11:05:00',
      'matchStatus': 'SEEKING_RIDER',
      'status': 'ACTIVE',
    },
  ];

  Future<List<Override>> buildOverrides(StubAdapter adapter) async {
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

  /// 详情页桩：任务 + 应征 + 任务会话 + 聊天链路。
  StubAdapter detailAdapter({
    Map<String, dynamic>? task,
    List<Map<String, dynamic>> applications = const [],
    List<Map<String, dynamic>> chatSessions = const [],
    void Function(Map<String, dynamic> body)? onCreateSession,
  }) {
    return StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': task ?? taskJson(),
        });
      }
      if (path == '/task/$taskNum/applications') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': applications,
        });
      }
      if (path == '/task/$taskNum/chat-sessions') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': chatSessions,
        });
      }
      if (path == '/chat/session/create') {
        onCreateSession?.call(
          Map<String, dynamic>.from(options.data as Map),
        );
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'id': 77,
            'name': '飞手乙',
            'type': 0,
            'userIds': [7, 9],
            'createTime': 1789000000,
            'unreadCount': 0,
            'taskNum': taskNum,
            'applicationId': 12,
          },
        });
      }
      if (path.startsWith('/chat/Message/messages/')) {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      if (path == '/chat/Message/read') {
        return jsonResponse(200, {'success': true, 'code': 200});
      }
      if (path == '/chat/session/list') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  Widget detailApp() => const MaterialApp(
        home: OrderDetailPage(taskNum: taskNum),
      );

  testWidgets('应征列表渲染：机型、载重、系统报价与应征时间', (tester) async {
    final adapter = detailAdapter(
      applications: applications,
      chatSessions: [
        {
          'sessionId': 55,
          'taskNum': taskNum,
          'applicationId': 11,
          'riderId': 8,
          'riderName': '飞手甲',
          'otherUserName': '飞手甲',
          'unreadCount': 3,
        },
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('应征飞手'), findsOneWidget);

    // 飞手 + 机型 + 载重
    expect(find.text('飞手甲'), findsOneWidget);
    expect(find.text('DJI FlyCart 30 · 载重 30 kg'), findsOneWidget);
    expect(find.text('飞手乙'), findsOneWidget);
    expect(find.text('DJI Matrice 350 RTK · 载重 2.7 kg'), findsOneWidget);

    // 系统报价只读展示（ADR-0003：平台算价，非飞手手填）
    expect(find.text('¥980'), findsOneWidget);
    expect(find.text('¥1200.5'), findsOneWidget);

    // 应征时间
    expect(find.text('应征于 2026-09-26 10:20'), findsOneWidget);
    expect(find.text('应征于 2026-09-26 11:05'), findsOneWidget);

    // 订单内红点：已有会话未读挂在对应应征项上
    expect(find.text('3'), findsOneWidget, reason: '任务会话未读数');

    // 服务端 actionHint 为唯一文案源
    expect(find.text('等待飞手应征，选定后下单支付'), findsOneWidget);
  });

  testWidgets('无价格输入控件（ADR-0003 禁止议价 UI）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          detailAdapter(applications: applications),
        ),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('应征飞手'), findsOneWidget);
    expect(find.byType(TextField), findsNothing,
        reason: '详情页不允许出现任何价格输入框');
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('空状态：暂无应征显示「等待飞手接单」', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(detailAdapter()),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('等待飞手接单'), findsOneWidget);
    expect(find.text('应征飞手'), findsOneWidget);
  });

  testWidgets('撮合结束（CONFIRMED）且无应征时不展示招募空状态', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          detailAdapter(task: taskJson(matchStatus: 'CONFIRMED')),
        ),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('应征飞手'), findsNothing);
    expect(find.text('等待飞手接单'), findsNothing,
        reason: '非撮合阶段不得误导用户等待接单');
  });

  testWidgets('点击无会话的应征项：创建订单内会话并进入聊天', (tester) async {
    Map<String, dynamic>? createdBody;
    final adapter = detailAdapter(
      applications: applications,
      onCreateSession: (body) => createdBody = body,
    );

    final router = GoRouter(
      initialLocation: '/order/$taskNum',
      routes: [
        GoRoute(
          path: '/order/:taskNum',
          builder: (_, state) =>
              OrderDetailPage(taskNum: state.pathParameters['taskNum']!),
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

    await tester.tap(find.text('飞手乙'));
    await tester.pumpAndSettle();

    expect(createdBody, isNotNull, reason: '无既有会话时走 /chat/session/create');
    expect(createdBody!['taskNum'], taskNum);
    expect(createdBody!['applicationId'], 12);
    expect((createdBody!['userIds'] as List), contains(9));
    expect(find.byType(ChatDetailPage), findsOneWidget,
        reason: '聊天从订单详情进入，不经全局消息 Tab');
  });

  testWidgets('点击已有会话的应征项：直达会话，不重复创建', (tester) async {
    var createCalls = 0;
    final adapter = detailAdapter(
      applications: [applications.first],
      chatSessions: [
        {
          'sessionId': 55,
          'taskNum': taskNum,
          'applicationId': 11,
          'riderId': 8,
          'riderName': '飞手甲',
          'otherUserName': '飞手甲',
          'unreadCount': 2,
        },
      ],
      onCreateSession: (_) => createCalls += 1,
    );

    final router = GoRouter(
      initialLocation: '/order/$taskNum',
      routes: [
        GoRoute(
          path: '/order/:taskNum',
          builder: (_, state) =>
              OrderDetailPage(taskNum: state.pathParameters['taskNum']!),
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

    await tester.tap(find.text('飞手甲'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailPage), findsOneWidget);
    expect(createCalls, 0, reason: '同任务 + 飞手已有会话直接复用');
    expect(
      adapter.requests
          .map((r) => r.uri.path)
          .where((p) => p == '/chat/Message/messages/55'),
      isNotEmpty,
      reason: '进入的是 chat-sessions 里既有的 55 号会话',
    );
  });

  testWidgets('下拉刷新拉到新应征：空状态 → 应征列表', (tester) async {
    var applicationCalls = 0;
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': taskJson(),
        });
      }
      if (path == '/task/$taskNum/applications') {
        applicationCalls += 1;
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': applicationCalls <= 1
              ? <Map<String, dynamic>>[]
              : [applications.first],
        });
      }
      if (path == '/task/$taskNum/chat-sessions') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      if (path == '/chat/session/list') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('等待飞手接单'), findsOneWidget);
    expect(applicationCalls, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(applicationCalls, greaterThanOrEqualTo(2),
        reason: '下拉刷新重新请求应征列表');
    expect(find.text('等待飞手接单'), findsNothing);
    expect(find.text('飞手甲'), findsOneWidget);
  });
}
