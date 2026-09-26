// 用户侧下单与双确认路径（TASK-APP-004 / ADR-0003 决定 2/3/4/5）：
//   1. 选定飞手 → 约定作业时间（未选拒绝提交）→ POST /task/{taskNum}/select-rider
//      （只发 applicationId + scheduledTime，无金额字段）→ 既有收银台；
//   2. 锁价红线：订单 totalAmount 与应征 quotedAmount 不一致时客户端不发起支付；
//   3. 状态展示：待飞手确认 / 已确认 / 进行中（描述文案以服务端 actionHint 为准，
//      双确认时间 userConfirmedAt/riderConfirmedAt 有则展示）；
//   4. 履约证据 + 确认完成：无证据时按钮禁用；证据加载失败时放行并透出服务端
//      DELIVERY_EVIDENCE_REQUIRED 文案；
//   5. 红线：选定弹窗与详情页均不存在任何价格输入控件。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/orders/order_detail_page.dart';
import 'package:uav_pilot_app/pages/pay/pay_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  const taskNum = 'T20260926-001';

  Map<String, dynamic> taskJson({
    String matchStatus = 'SEEKING_RIDER',
    String taskStatus = 'IDLE',
    String? actionHint = '等待飞手应征，选定后下单支付',
    String? orderStatus,
    String? orderNum,
    double? totalAmount,
    double? quotedAmount,
    int? riderId,
    String? riderName,
    String? scheduledTime,
    String? userConfirmedAt,
    String? riderConfirmedAt,
  }) {
    return {
      'id': 1,
      'taskNum': taskNum,
      'taskName': '山顶基站建材吊运',
      'userId': 7,
      'taskType': 'TRANSPORT',
      'taskStatus': taskStatus,
      'matchStatus': matchStatus,
      'actionHint': actionHint,
      'orderNum': orderNum,
      'orderStatus': orderStatus,
      'totalAmount': totalAmount,
      'quotedAmount': quotedAmount,
      'riderId': riderId,
      'riderName': riderName,
      'scheduledTime': scheduledTime,
      'userConfirmedAt': userConfirmedAt,
      'riderConfirmedAt': riderConfirmedAt,
      'createTime': '2026-09-26T09:00:00',
      'updateTime': '2026-09-26T09:30:00',
    };
  }

  /// 选定后的待支付任务（select-rider 成功后的权威状态）。
  Map<String, dynamic> awaitingPaymentTask() => taskJson(
        matchStatus: 'AWAITING_PAYMENT',
        actionHint: '已选定飞手，请完成支付',
        orderNum: 'ORD-1',
        orderStatus: 'PENDING',
        totalAmount: 980,
        quotedAmount: 980,
        riderId: 8,
        riderName: '飞手甲',
        scheduledTime: '2026-09-27 09:00:00',
      );

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

  /// 详情页桩：任务详情 + 应征 + 会话 + 证据 + 确认 + 收银台。
  StubAdapter detailAdapter({
    required Map<String, dynamic> task,
    List<Map<String, dynamic>> applications = const [],
    List<Map<String, dynamic>>? attachments,
    bool attachmentsFailed = false,
    int confirmStatus = 200,
    Map<String, dynamic> confirmBody = const {
      'success': true,
      'code': 200,
    },
    Map<String, dynamic>? order,
  }) {
    return StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': task,
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
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      if (path == '/tasks/$taskNum/attachments') {
        if (attachmentsFailed) {
          return jsonResponse(500, {
            'success': false,
            'message': '附件服务暂不可用',
          });
        }
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': attachments ?? const [],
        });
      }
      if (path == '/task/confirm') {
        return jsonResponse(confirmStatus, confirmBody);
      }
      if (path == '/order/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': order ??
              {
                'orderNum': 'ORD-1',
                'totalAmount': 980,
                'orderStatus': 0,
                'taskName': '山顶基站建材吊运',
              },
        });
      }
      if (path == '/chat/session/list') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      return jsonResponse(200, {'success': false, 'message': 'unexpected stub: $path'});
    });
  }

  Widget detailApp() => const MaterialApp(
        home: OrderDetailPage(taskNum: taskNum),
      );

  /// 页面红线：无任何价格输入控件（ADR-0003 禁止改价/议价 UI）。
  void expectNoPriceInputs(WidgetTester tester) {
    expect(find.byType(TextField), findsNothing,
        reason: '不允许出现任何价格输入框');
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Slider), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  }

  testWidgets('选定飞手 → 约定时间 → select-rider → 收银台金额 = 系统报价',
      (tester) async {
    var selected = false;
    Map<String, dynamic>? selectBody;
    // 桩按 selected 标志动态返回：下单前招募中，下单后待支付。
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': selected ? awaitingPaymentTask() : taskJson(),
        });
      }
      if (path == '/task/$taskNum/applications') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': selected
              ? [
                  {...applications.first, 'status': 'SELECTED'},
                  {...applications.last, 'status': 'CLOSED'},
                ]
              : applications,
        });
      }
      if (path == '/task/$taskNum/chat-sessions') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      if (path == '/task/$taskNum/select-rider') {
        selectBody = Map<String, dynamic>.from(options.data as Map);
        selected = true;
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': awaitingPaymentTask(),
        });
      }
      if (path == '/chat/session/list') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
      }
      if (path == '/order/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-1',
            'totalAmount': 980,
            'orderStatus': 0,
            'taskName': '山顶基站建材吊运',
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'unexpected stub: $path'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('选定飞手'), findsNWidgets(2), reason: '招募阶段每条应征可选定');

    // 打开选定弹窗：系统报价只读展示 + 未选时间拒绝提交 + 无价格输入控件。
    await tester.tap(find.text('选定飞手').first);
    await tester.pumpAndSettle();
    expect(find.text('选定飞手下单'), findsOneWidget);
    expect(find.text('¥980（平台计价）'), findsOneWidget);
    expectNoPriceInputs(tester);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认下单'))
          .onPressed,
      isNull,
      reason: '未选择约定作业时间时拒绝提交',
    );
    expect(find.text('未选择约定作业时间，无法提交下单'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '确认下单'));
    await tester.pump();
    expect(selectBody, isNull, reason: '禁用态提交不产生请求');

    // 选择约定作业时间（日期 + 时间滚动选择器）。
    await tester.tap(find.text('选择日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择时间'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '确定'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认下单'))
          .onPressed,
      isNotNull,
      reason: '约定时间齐备后允许提交',
    );

    await tester.tap(find.widgetWithText(FilledButton, '确认下单'));
    await tester.pumpAndSettle();

    // select-rider 请求体：只有 applicationId + scheduledTime，绝无金额字段。
    expect(selectBody, isNotNull, reason: '选定飞手调用 select-rider');
    expect(selectBody!['applicationId'], 11);
    expect(
      selectBody!['scheduledTime'],
      matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:00$')),
      reason: '约定作业时间为 yyyy-MM-dd HH:mm:ss',
    );
    expect(
      selectBody!.keys
          .where((k) =>
              k.toLowerCase().contains('amount') ||
              k.toLowerCase().contains('price') ||
              k.toLowerCase().contains('quote')),
      isEmpty,
      reason: 'ADR-0003 禁止客户端提交任何金额字段',
    );

    // 成功后直接进入既有收银台，金额只读 = 系统报价。
    expect(find.byType(PayPage), findsOneWidget);
    expect(find.text('应付金额'), findsOneWidget);
    expect(find.text('¥980.00'), findsWidgets, reason: '收银台金额 = quotedAmount');
    expect(find.byType(TextField), findsNothing, reason: '收银台无金额输入');
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('订单金额与应征报价不一致：不发起支付并提示', (tester) async {
    final adapter = detailAdapter(
      task: taskJson(
        matchStatus: 'AWAITING_PAYMENT',
        actionHint: '已选定飞手，请完成支付',
        orderNum: 'ORD-9',
        orderStatus: 'PENDING',
        totalAmount: 1200,
        quotedAmount: 980,
        riderId: 8,
        riderName: '飞手甲',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('去支付'), findsOneWidget);
    await tester.tap(find.text('去支付'));
    await tester.pumpAndSettle();

    expect(
      find.byType(PayPage),
      findsNothing,
      reason: '锁价不一致拒绝发起支付',
    );
    expect(
      adapter.requests.where((r) => r.uri.path.startsWith('/pay/')),
      isEmpty,
      reason: '未发起任何支付请求',
    );
    expect(
      find.textContaining('支付金额与应征报价不一致'),
      findsOneWidget,
      reason: '提示用户金额不一致',
    );
  });

  testWidgets('待飞手确认：状态 + 双确认时间 + 联系飞手，不落删除分支',
      (tester) async {
    final adapter = detailAdapter(
      task: taskJson(
        matchStatus: 'AWAITING_RIDER_CONFIRM',
        actionHint: '已支付，等待飞手确认约定作业时间',
        orderStatus: 'PAID',
        orderNum: 'ORD-1',
        totalAmount: 980,
        quotedAmount: 980,
        riderId: 8,
        riderName: '飞手甲',
        scheduledTime: '2026-09-27 09:00:00',
        userConfirmedAt: '2026-09-26T12:00:00',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 描述文案以服务端 actionHint 为准
    expect(find.text('已支付，等待飞手确认约定作业时间'), findsOneWidget);
    // 状态名 + 用户确认时间（飞手未确认则不展示其时间）
    expect(find.text('待飞手确认'), findsOneWidget);
    expect(find.text('用户确认时间'), findsOneWidget);
    expect(find.text('2026-09-26 12:00'), findsOneWidget);
    expect(find.text('飞手确认时间'), findsNothing);
    // 双确认阶段提供履约沟通入口，而非删除任务
    expect(find.text('联系飞手'), findsOneWidget);
    expect(find.text('删除任务'), findsNothing);
    expect(find.text('去支付'), findsNothing, reason: '已支付不再出现支付入口');
  });

  testWidgets('已确认（双确认齐备）：展示双方确认时间与联系入口', (tester) async {
    final adapter = detailAdapter(
      task: taskJson(
        matchStatus: 'CONFIRMED',
        actionHint: '双方已确认，可以开始作业',
        orderStatus: 'PAID',
        orderNum: 'ORD-1',
        totalAmount: 980,
        quotedAmount: 980,
        riderId: 8,
        riderName: '飞手甲',
        scheduledTime: '2026-09-27 09:00:00',
        userConfirmedAt: '2026-09-26T12:00:00',
        riderConfirmedAt: '2026-09-26T12:30:00',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('双方已确认，可以开始作业'), findsOneWidget);
    expect(find.text('已确认'), findsOneWidget);
    expect(find.text('用户确认时间'), findsOneWidget);
    expect(find.text('飞手确认时间'), findsOneWidget);
    expect(find.text('2026-09-26 12:00'), findsOneWidget);
    expect(find.text('2026-09-26 12:30'), findsOneWidget);
    expect(find.text('联系飞手'), findsOneWidget);
    expect(find.text('删除任务'), findsNothing);
  });

  testWidgets('进行中：状态展示为进行中', (tester) async {
    final adapter = detailAdapter(
      task: taskJson(
        matchStatus: 'CONFIRMED',
        taskStatus: 'IN_PROGRESS',
        actionHint: '双方已确认，可以开始作业',
        orderStatus: 'PAID',
        orderNum: 'ORD-1',
        totalAmount: 980,
        quotedAmount: 980,
        riderId: 8,
        riderName: '飞手甲',
        userConfirmedAt: '2026-09-26T12:00:00',
        riderConfirmedAt: '2026-09-26T12:30:00',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('进行中'), findsOneWidget);
    expect(find.text('联系飞手'), findsOneWidget);
    expect(find.text('2026-09-26 12:30'), findsOneWidget);
  });

  testWidgets('无履约证据：「确认完成」禁用且不发确认请求', (tester) async {
    final adapter = detailAdapter(
      task: taskJson(
        matchStatus: 'PENDING_ACCEPTANCE',
        taskStatus: 'IN_PROGRESS',
        actionHint: '飞手已执飞，等待上传履约证据',
        orderStatus: 'WAITING_CONFIRM',
        orderNum: 'ORD-1',
        totalAmount: 980,
        quotedAmount: 980,
        riderId: 8,
        riderName: '飞手甲',
      ),
      attachments: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 证据区块位于首屏之下：滚动至可见以触发附件列表加载。
    await tester.scrollUntilVisible(
      find.text('交付成果'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('交付成果'), findsOneWidget, reason: '证据列表可见');
    expect(
      adapter.requests
          .where((r) => r.uri.path == '/tasks/$taskNum/attachments'),
      isNotEmpty,
      reason: '证据列表已拉取',
    );
    final confirm = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '确认完成'));
    expect(confirm.onPressed, isNull, reason: '无证据时禁用确认完成');
    expect(
      find.text('暂无履约证据，待飞手上传后方可确认完成'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, '确认完成'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing, reason: '禁用态不弹确认框');
    expect(
      adapter.requests.where((r) => r.uri.path == '/task/confirm'),
      isEmpty,
      reason: '未发起确认请求',
    );
  });

  testWidgets('服务端拒确认（DELIVERY_EVIDENCE_REQUIRED）：文案透出', (tester) async {
    final adapter = detailAdapter(
      task: taskJson(
        matchStatus: 'PENDING_ACCEPTANCE',
        taskStatus: 'IN_PROGRESS',
        actionHint: '飞手已执飞，等待验收',
        orderStatus: 'WAITING_CONFIRM',
        orderNum: 'ORD-1',
        totalAmount: 980,
        quotedAmount: 980,
        riderId: 8,
        riderName: '飞手甲',
      ),
      attachmentsFailed: true, // 证据列表拉取失败 → 客户端不拦，交服务端裁决
      confirmStatus: 400,
      confirmBody: const {
        'success': false,
        'errorCode': 'DELIVERY_EVIDENCE_REQUIRED',
        'message': '请先上传至少一项履约证据',
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: detailApp(),
      ),
    );
    await tester.pumpAndSettle();

    final confirm = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '确认完成'));
    expect(confirm.onPressed, isNotNull, reason: '证据状态未知时交由服务端裁决');

    await tester.tap(find.widgetWithText(FilledButton, '确认完成'));
    await tester.pumpAndSettle();

    final dialogConfirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, '确认完成'),
    );
    expect(dialogConfirm, findsOneWidget);
    await tester.tap(dialogConfirm);
    await tester.pumpAndSettle();

    expect(
      adapter.requests.where((r) => r.uri.path == '/task/confirm'),
      isNotEmpty,
      reason: '确认请求已发起并被服务端拒绝',
    );
    expect(
      find.textContaining('请先上传至少一项履约证据'),
      findsOneWidget,
      reason: '服务端 DELIVERY_EVIDENCE_REQUIRED 文案透出',
    );
  });
}
