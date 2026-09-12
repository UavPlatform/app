// 验收语义 UI 测试（t42：actionHint 矩阵直接渲染/完成说明/交付成果占位）。
// 注意：完成说明/交付成果区块位于首屏之下（ListView keep-alive bucket），
// 断言前需滚动至可见，否则默认 finder 会跳过。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/orders/order_detail_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  Map<String, dynamic> taskJson({
    String taskStatus = 'IDLE',
    String orderStatus = 'PENDING',
    String? actionHint,
    String? completeNote,
    int? riderId,
    String riderName = '飞手甲',
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
      'actionHint': actionHint,
      'completeNote': completeNote,
      'riderId': riderId,
      'riderName': riderName,
      'createTime': '2026-09-12T10:00:00',
      'updateTime': '2026-09-12T10:00:00',
    };
  }

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

  StubAdapter detailAdapter(Map<String, dynamic> task) {
    return StubAdapter((options) async {
      if (options.uri.path == '/task/detail') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': task});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  group('操作提示矩阵直接渲染（t32 actionHint，不端上拼装）', () {
    testWidgets('IDLE+PENDING 渲染服务端提示「待支付：支付后任务将进入接单大厅」',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(
            detailAdapter(taskJson(actionHint: '待支付：支付后任务将进入接单大厅')),
          ),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('待支付：支付后任务将进入接单大厅'), findsOneWidget);
    });

    testWidgets('IDLE+PAID 渲染「已支付：等待飞手接单」', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(
            detailAdapter(
              taskJson(orderStatus: 'PAID', actionHint: '已支付：等待飞手接单'),
            ),
          ),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('已支付：等待飞手接单'), findsOneWidget);
    });

    testWidgets('COMPLETED+WAITING_CONFIRM 渲染「待验收：飞手已完成，请确认验收」',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(
            detailAdapter(
              taskJson(
                taskStatus: 'COMPLETED',
                orderStatus: 'WAITING_CONFIRM',
                actionHint: '待验收：飞手已完成，请确认验收',
              ),
            ),
          ),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('待验收：飞手已完成，请确认验收'), findsOneWidget);
    });

    testWidgets('actionHint 缺省（后端未下发）不渲染提示横幅且不报错', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(detailAdapter(taskJson())),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('支付后任务将进入接单大厅'), findsNothing);
      expect(find.text('任务编号'), findsOneWidget, reason: '页面正常渲染');
    });
  });

  group('完成说明（t32 completeNote）', () {
    testWidgets('飞手完成说明在用户详情可见', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(
            detailAdapter(
              taskJson(
                taskStatus: 'COMPLETED',
                orderStatus: 'WAITING_CONFIRM',
                actionHint: '待验收：飞手已完成，请确认验收',
                completeNote: '已完成 3 个点位航拍，成片已打包',
                riderId: 8,
              ),
            ),
          ),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 区块位于首屏之下：滚动至可见后断言
      await tester.scrollUntilVisible(
        find.text('完成说明'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('完成说明'), findsOneWidget);
      expect(find.text('已完成 3 个点位航拍，成片已打包'), findsOneWidget);
    });

    testWidgets('无完成说明时不渲染该区块', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(detailAdapter(taskJson(riderId: 8))),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('完成说明'), findsNothing);
    });
  });

  group('交付成果区块（t44：真实附件列表与上传入口）', () {
    testWidgets('已接单任务展示交付成果区块（空态含补充上传入口）', (tester) async {
      final adapter = StubAdapter((options) async {
        if (options.uri.path == '/task/detail') {
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'data': taskJson(riderId: 8),
          });
        }
        if (options.uri.path == '/tasks/T20260912-001/attachments') {
          return jsonResponse(200, {
            'success': true,
            'code': 200,
            'data': [],
          });
        }
        return jsonResponse(200, {'success': false, 'message': 'stub'});
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(adapter),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('交付成果'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('暂无交付成果'), findsOneWidget);
      expect(find.textContaining('补充上传'), findsOneWidget);
    });

    testWidgets('未接单任务不展示交付成果区块', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: await buildOverrides(detailAdapter(taskJson())),
          child: const MaterialApp(
            home: OrderDetailPage(taskNum: 'T20260912-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('交付成果'), findsNothing);
    });
  });

  testWidgets('文案统一：订单状态行沿用 t29 OrderStatusCode 映射', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(
          detailAdapter(taskJson(orderStatus: 'WAITING_CONFIRM', riderId: 8)),
        ),
        child: const MaterialApp(
          home: OrderDetailPage(taskNum: 'T20260912-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('订单状态'), findsOneWidget);
    expect(find.text('待验收'), findsOneWidget);
  });
}
