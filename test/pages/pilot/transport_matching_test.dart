// 飞手端吊运应征与订单确认（TASK-APP-005 / ADR-0003）：
//   1. 任务大厅默认 TRANSPORT 筛选，卡片展示货物并进入任务详情（应征按钮在详情内）；
//   2. 应征：绑定设备映射机型预选 → apply 只发 taskNum+aircraftModelId（无金额字段），
//      成功只读展示系统报价 quotedAmount，失败展示服务端 message（超重/机型不可吊运等）；
//   3. 机型未选拒绝提交；未绑机/未映射 → 引导去绑机页；
//   4. 我的接单分组：待用户下单 / 待我确认 / 已确认待执飞；确认订单回显约定时间，
//      未确认前不出现执飞入口，确认后出现「打开 djifly」；
//   5. 红线：相关页面不存在任何价格输入控件（无议价 UI）。

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/chat/chat_detail_page.dart';
import 'package:uav_pilot_app/pages/orders/order_detail_page.dart';
import 'package:uav_pilot_app/pages/pilot/my_jobs_page.dart';
import 'package:uav_pilot_app/pages/pilot/task_hall_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../../test_support.dart';

void main() {
  const taskNum = 'T20260926-001';

  Map<String, dynamic> taskJson({
    String num = taskNum,
    String name = '山顶基站建材吊运',
    String taskType = 'TRANSPORT',
    String taskStatus = 'IDLE',
    String matchStatus = 'SEEKING_RIDER',
    String? actionHint = '等待飞手应征，选定后下单支付',
    String? scheduledTime,
    double? quotedAmount,
    double? totalAmount,
    bool withCargo = true,
  }) {
    return {
      'id': 1,
      'taskNum': num,
      'taskName': name,
      'userId': 7,
      'taskType': taskType,
      'taskStatus': taskStatus,
      'matchStatus': matchStatus,
      'actionHint': actionHint,
      'createTime': '2026-09-26T09:00:00',
      if (withCargo) 'cargoWeightKg': 25,
      if (withCargo) 'cargoCategory': 'CONSTRUCTION',
      'scheduledTime': ?scheduledTime,
      'quotedAmount': ?quotedAmount,
      'totalAmount': ?totalAmount,
    };
  }

  // 绑定设备映射到机型 3（FlyCart 30）：应征表单应优先预选该机型。
  final boundDrone = <String, dynamic>{
    'id': 1,
    'userId': 8,
    'djiId': 'FLYCART-001',
    'aircraftModelId': 3,
    'createTime': '2026-09-26T08:00:00',
  };

  final catalog = <Map<String, dynamic>>[
    {
      'id': 3,
      'displayName': 'DJI FlyCart 30',
      'modelCode': 'FC30',
      'maxPayloadKg': 30,
      'transportEnabled': true,
      'coefficient': 1.0,
    },
    {
      'id': 4,
      'displayName': 'DJI Matrice 350 RTK',
      'modelCode': 'M350RTK',
      'maxPayloadKg': 2.7,
      'transportEnabled': false,
      'coefficient': 1.0,
    },
  ];

  Map<String, dynamic> page(List<Map<String, dynamic>> tasks) => {
        'tasks': tasks,
        'currentPage': 1,
        'totalPages': 1,
        'totalElements': tasks.length,
      };

  Future<List<Override>> buildOverrides(StubAdapter adapter) async {
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 8, role: 1),
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

  /// 飞手端桩：详情（confirm 后切 confirmedDetail）/ 大厅 / 我的接单 /
  /// 绑机 / 机型目录 / 应征 / 确认订单 / 聊天链路。
  StubAdapter pilotAdapter({
    Map<String, dynamic>? detail,
    Map<String, dynamic>? confirmedDetail,
    List<Map<String, dynamic>> square = const [],
    List<Map<String, dynamic>> myTasks = const [],
    List<Map<String, dynamic>> drones = const [],
    Map<String, dynamic>? applyData,
    String applyMessage = '货物重量 50 kg 超过机型最大载重 30 kg',
    bool confirmOk = true,
    void Function(RequestOptions options)? onSessionCreate,
  }) {
    var confirmed = false;
    return StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/rider/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': confirmed && confirmedDetail != null
              ? confirmedDetail
              : (detail ?? taskJson()),
        });
      }
      if (path == '/rider/square') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': page(square)});
      }
      if (path == '/rider/my-tasks') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': page(myTasks)});
      }
      if (path == '/rider/my-tasks/history') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': page(const [])});
      }
      if (path == '/rider/drone/list') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': drones});
      }
      if (path == '/api/aircraft-models') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': catalog});
      }
      if (path == '/rider/apply') {
        if (applyData != null) {
          return jsonResponse(200, {'success': true, 'code': 200, 'data': applyData});
        }
        return jsonResponse(400, {
          'success': false,
          'errorCode': 'EXCEEDS_PAYLOAD',
          'message': applyMessage,
        });
      }
      if (path == '/rider/confirm-order') {
        if (!confirmOk) {
          return jsonResponse(400, {
            'success': false,
            'message': '订单状态不允许确认',
          });
        }
        confirmed = true;
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': confirmedDetail ?? detail ?? taskJson(matchStatus: 'CONFIRMED'),
        });
      }
      if (path == '/chat/session/list') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      if (path == '/chat/session/create') {
        onSessionCreate?.call(options);
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'id': 77,
            'name': '用户',
            'type': 0,
            'userIds': [7, 8],
            'createTime': 1789000000,
            'unreadCount': 0,
            'taskNum': taskNum,
            'otherUserName': '用户',
          },
        });
      }
      if (path.startsWith('/chat/Message/messages/')) {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      if (path == '/chat/Message/read') {
        return jsonResponse(200, {'success': true, 'code': 200});
      }
      return jsonResponse(200, {'success': false, 'message': 'unexpected stub: $path'});
    });
  }

  void expectNoPriceInputs() {
    expect(find.byType(TextField), findsNothing,
        reason: 'ADR-0003：页面不允许出现任何价格输入框');
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  }

  testWidgets('任务大厅默认 TRANSPORT 筛选，卡片展示货物并进入任务详情', (tester) async {
    final adapter = pilotAdapter(
      detail: taskJson(),
      square: [
        taskJson(),
        taskJson(
          num: 'T20260926-002',
          name: '婚礼航拍跟拍',
          taskType: 'AERIAL_PHOTO',
          withCargo: false,
        ),
      ],
      drones: [boundDrone],
    );
    final router = GoRouter(initialLocation: '/pilot/tasks', routes: [
      GoRoute(path: '/pilot/tasks', builder: (_, _) => const TaskHallPage()),
      GoRoute(
        path: '/order/:taskNum',
        builder: (_, state) =>
            OrderDetailPage(taskNum: state.pathParameters['taskNum']!),
      ),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('山顶基站建材吊运'), findsOneWidget);
    expect(find.text('婚礼航拍跟拍'), findsNothing,
        reason: '默认筛选 TRANSPORT，非吊运任务不展示');
    expect(find.text('25 kg · 建材'), findsOneWidget, reason: '卡片展示货物信息');
    expectNoPriceInputs();

    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(find.text('婚礼航拍跟拍'), findsOneWidget, reason: '可切换查看全部品类');

    await tester.tap(find.text('山顶基站建材吊运'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailPage), findsOneWidget, reason: '卡片进入任务详情');
    expect(find.text('应征任务'), findsOneWidget, reason: '详情内提供应征按钮');
    expect(find.text('25 kg · 建材'), findsOneWidget, reason: '详情任务信息展示货物');
  });

  testWidgets('应征成功：绑定机型预选、请求无金额字段、只读系统报价、聊天带 applicationId',
      (tester) async {
    Map<String, dynamic>? createdBody;
    final adapter = pilotAdapter(
      detail: taskJson(),
      drones: [boundDrone],
      applyData: {
        'applicationId': 21,
        'taskNum': taskNum,
        'riderId': 8,
        'riderName': '我',
        'aircraftModelId': 3,
        'aircraftModelName': 'DJI FlyCart 30',
        'modelCode': 'FC30',
        'maxPayloadKg': 30,
        'quotedAmount': 980,
        'appliedAt': '2026-09-26T10:20:00',
        'matchStatus': 'NEGOTIATING',
        'status': 'ACTIVE',
      },
      onSessionCreate: (options) =>
          createdBody = Map<String, dynamic>.from(options.data as Map),
    );
    final router = GoRouter(initialLocation: '/order/$taskNum', routes: [
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
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // 绑定设备映射的机型被优先预选
    expect(find.text('DJI FlyCart 30 · 载重 30 kg'), findsOneWidget);
    expect(find.text('应征任务'), findsOneWidget);

    await tester.tap(find.text('应征任务'));
    await tester.pumpAndSettle();

    // 请求只含 taskNum + aircraftModelId：客户端不传金额，无法改价
    final applyReq =
        adapter.requests.firstWhere((r) => r.uri.path == '/rider/apply');
    expect(applyReq.queryParameters['taskNum'], taskNum);
    expect(applyReq.queryParameters['aircraftModelId'], 3);
    expect((applyReq.data as Map).keys.toSet(), {'taskNum', 'aircraftModelId'},
        reason: 'ADR-0003：应征请求不得携带金额字段');

    // 成功后只读展示系统报价
    expect(find.text('应征成功，等待用户选定下单'), findsOneWidget);
    expect(find.text('¥980（平台计价）'), findsOneWidget);
    expectNoPriceInputs();

    // 订单内聊天：taskNum + applicationId → ChatDetailPage
    await tester.tap(find.text('联系用户'));
    await tester.pumpAndSettle();
    expect(createdBody, isNotNull, reason: '聊天走 /chat/session/create');
    expect(createdBody!['taskNum'], taskNum);
    expect(createdBody!['applicationId'], 21);
    expect(find.byType(ChatDetailPage), findsOneWidget,
        reason: '聊天从任务详情进入订单内会话');
  });

  testWidgets('应征被拒：展示服务端 message（超重），不出现成功态', (tester) async {
    final adapter = pilotAdapter(
      detail: taskJson(),
      drones: [boundDrone],
      applyMessage: '货物重量 50 kg 超过机型最大载重 30 kg',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: OrderDetailPage(taskNum: taskNum)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('应征任务'));
    await tester.pumpAndSettle();

    expect(find.text('货物重量 50 kg 超过机型最大载重 30 kg'), findsOneWidget,
        reason: '失败原因直接透出服务端 message');
    expect(find.text('应征成功，等待用户选定下单'), findsNothing);
    expect(
      adapter.requests.where((r) => r.uri.path == '/rider/apply').length,
      1,
    );
    expectNoPriceInputs();
  });

  testWidgets('机型选择校验：未选机型拒绝提交，不发 apply 请求', (tester) async {
    final adapter = pilotAdapter(
      detail: taskJson(),
      // 绑定设备映射的机型 99 不在机型目录中 → 无法预选，处于未选状态。
      drones: [
        {'id': 1, 'userId': 8, 'djiId': 'OLD-001', 'aircraftModelId': 99},
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: OrderDetailPage(taskNum: taskNum)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('请选择机型'), findsOneWidget, reason: '目录中无绑定机型时处于未选状态');

    await tester.tap(find.text('应征任务'));
    await tester.pumpAndSettle();

    expect(find.text('请先选择本次使用的机型'), findsOneWidget);
    expect(adapter.requests.where((r) => r.uri.path == '/rider/apply'), isEmpty,
        reason: '未选机型不得发起应征');
  });

  testWidgets('未绑机/未映射机型：引导去绑机页，不提供应征提交', (tester) async {
    final adapter = pilotAdapter(detail: taskJson(), drones: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: OrderDetailPage(taskNum: taskNum)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('尚未绑定已映射机型的无人机，无法应征吊运任务。'), findsOneWidget);
    expect(find.text('去绑定设备'), findsOneWidget);
    expect(find.text('应征任务'), findsNothing);
  });

  testWidgets('确认订单回显约定时间；未确认不显示执飞入口，确认后出现', (tester) async {
    final awaiting = taskJson(
      matchStatus: 'AWAITING_RIDER_CONFIRM',
      actionHint: '已支付，等待你确认约定作业时间',
      scheduledTime: '2026-09-28T09:00:00',
      quotedAmount: 980,
      totalAmount: 980,
    );
    final confirmedTask = taskJson(
      matchStatus: 'CONFIRMED',
      taskStatus: 'IN_PROGRESS',
      actionHint: '双方已确认，可以开始作业',
      scheduledTime: '2026-09-28T09:00:00',
      quotedAmount: 980,
      totalAmount: 980,
    );
    final adapter = pilotAdapter(
      detail: awaiting,
      confirmedDetail: confirmedTask,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: OrderDetailPage(taskNum: taskNum)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('打开 djifly'), findsNothing,
        reason: '未确认订单不得显示执飞入口');
    expect(find.text('确认订单'), findsOneWidget);
    expect(find.text('已支付，等待你确认约定作业时间'), findsOneWidget,
        reason: '文案以服务端 actionHint 为准');
    expect(find.text('2026-09-28 09:00'), findsOneWidget, reason: '约定时间回显');
    expect(find.text('¥980（平台计价）'), findsOneWidget, reason: '系统报价只读');

    await tester.tap(find.text('确认订单'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('确认按约定作业时间「2026-09-28 09:00」'),
      findsOneWidget,
      reason: '确认前回显约定作业时间',
    );

    await tester.tap(find.text('确认接单'));
    await tester.pumpAndSettle();

    final confirmReq = adapter.requests
        .firstWhere((r) => r.uri.path == '/rider/confirm-order');
    expect(confirmReq.queryParameters['taskNum'], taskNum);
    expect(find.text('打开 djifly'), findsOneWidget, reason: '确认后提供执飞引导');
    expectNoPriceInputs();

    // 排干 SnackBar 计时器后结束
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('我的接单分组与确认流程；未确认不显示执飞入口', (tester) async {
    // 三组卡片纵向较长：放大视口让三组同屏，避免懒构建导致查找不到。
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final negotiating = taskJson(
      num: 'T20260926-011',
      name: '仓库钢材吊运',
      matchStatus: 'NEGOTIATING',
      actionHint: '已应征，等待用户选定下单',
    );
    final awaiting = taskJson(
      num: 'T20260926-012',
      name: '工地砂石吊运',
      matchStatus: 'AWAITING_RIDER_CONFIRM',
      actionHint: '已支付，等待你确认约定作业时间',
      scheduledTime: '2026-09-28T09:00:00',
      quotedAmount: 980,
      totalAmount: 980,
    );
    final confirmed = taskJson(
      num: 'T20260926-013',
      name: '山顶设备吊运',
      matchStatus: 'CONFIRMED',
      taskStatus: 'IN_PROGRESS',
      actionHint: '双方已确认，可以开始作业',
      scheduledTime: '2026-09-29T14:00:00',
      quotedAmount: 1200,
      totalAmount: 1200,
    );
    final adapter = pilotAdapter(
      detail: awaiting,
      confirmedDetail: {
        ...awaiting,
        'matchStatus': 'CONFIRMED',
        'taskStatus': 'IN_PROGRESS',
        'actionHint': '双方已确认，可以开始作业',
      },
      myTasks: [negotiating, awaiting, confirmed],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: MyJobsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('待用户下单 (1)'), findsOneWidget);
    expect(find.text('待我确认 (1)'), findsOneWidget);
    expect(find.text('已确认待执飞 (1)'), findsOneWidget);
    expect(find.text('已应征，等待用户选定下单'), findsOneWidget,
        reason: '文案以服务端 actionHint 为准');
    expect(find.text('已支付，等待你确认约定作业时间'), findsOneWidget);
    expect(find.text('约定作业时间: 2026-09-28 09:00'), findsOneWidget);
    expect(find.text('打开 djifly'), findsOneWidget,
        reason: '仅已确认任务有执飞入口，未确认任务不显示');
    expectNoPriceInputs();

    await tester.ensureVisible(find.text('确认订单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认订单'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2026-09-28 09:00'), findsWidgets,
        reason: '确认前回显约定作业时间');

    await tester.tap(find.text('确认接单'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.where((r) => r.uri.path == '/rider/confirm-order'),
      isNotEmpty,
      reason: '确认按钮调用 confirm-order',
    );
    expect(find.text('待我确认 (1)'), findsNothing);
    expect(find.text('已确认待执飞 (2)'), findsOneWidget,
        reason: '确认后任务推进到已确认分组');
    expect(find.text('打开 djifly'), findsNWidgets(2));
    expectNoPriceInputs();

    // 排干 SnackBar 计时器后结束
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('飞手端页面均无价格输入控件（ADR-0003 禁止议价 UI）', (tester) async {
    // 任务大厅
    var overrides = await buildOverrides(pilotAdapter(
      detail: taskJson(),
      square: [taskJson()],
      drones: [boundDrone],
    ));
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('hall'),
        overrides: overrides,
        child: const MaterialApp(home: TaskHallPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('任务大厅'), findsOneWidget);
    expectNoPriceInputs();

    // 任务详情（应征表单）
    overrides = await buildOverrides(pilotAdapter(
      detail: taskJson(),
      drones: [boundDrone],
    ));
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('detail'),
        overrides: overrides,
        child: const MaterialApp(home: OrderDetailPage(taskNum: taskNum)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('应征任务'), findsOneWidget, reason: '应征表单已渲染');
    expectNoPriceInputs();

    // 我的接单
    overrides = await buildOverrides(pilotAdapter(
      myTasks: [
        taskJson(
          num: 'T20260926-012',
          name: '工地砂石吊运',
          matchStatus: 'AWAITING_RIDER_CONFIRM',
          actionHint: '已支付，等待你确认约定作业时间',
          scheduledTime: '2026-09-28T09:00:00',
          quotedAmount: 980,
          totalAmount: 980,
        ),
      ],
    ));
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('jobs'),
        overrides: overrides,
        child: const MaterialApp(home: MyJobsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('确认订单'), findsOneWidget);
    expectNoPriceInputs();
  });
}
