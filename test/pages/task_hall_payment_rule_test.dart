// 飞手任务大厅接单支付规则适配（t30②③：t22 过滤后展示确认 + TASK_NOT_PAID 提示）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/pilot/task_hall_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
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

  StubAdapter squareAdapter({int taskCount = 1}) {
    return StubAdapter((options) async {
      if (options.uri.path == '/rider/square') {
        // t22：/rider/square 服务端已过滤，仅返回已支付任务
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'tasks': [
              for (var i = 0; i < taskCount; i++)
                {
                  'id': i + 1,
                  'taskNum': 'T20260912-00${i + 1}',
                  'taskName': '已支付任务 ${i + 1}',
                  'userId': 7,
                  'taskType': 'AERIAL_PHOTO',
                  'taskStatus': 'IDLE',
                  'totalAmount': 120,
                  'totalDistance': 3200,
                  'description': '大厅可见的已支付任务',
                  'createTime': '2026-09-12T10:00:00',
                  'updateTime': '2026-09-12T10:00:00',
                },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': taskCount,
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  testWidgets('大厅仅渲染 /rider/square 返回的可接任务（t22 过滤后展示层确认）',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(squareAdapter(taskCount: 1)),
        child: const MaterialApp(home: TaskHallPage()),
      ),
    );
    await tester.pumpAndSettle();

    // 服务端过滤结果原样展示：1 个可接任务 → 1 张卡片 + 1 个接单按钮
    expect(find.text('已支付任务 1'), findsOneWidget);
    expect(find.text('立即接单'), findsOneWidget);
  });

  testWidgets('大厅空态提示支付规则', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(squareAdapter(taskCount: 0)),
        child: const MaterialApp(home: TaskHallPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无可用任务'), findsOneWidget);
    expect(find.textContaining('支付后的任务才会进入大厅'), findsOneWidget);
  });

  testWidgets('accept 失败（TASK_NOT_PAID）透传服务端明确提示', (tester) async {
    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/rider/accept') {
        // t22 契约：订单非 PAID → 400 TASK_NOT_PAID
        return jsonResponse(400, {
          'success': false,
          'code': 400,
          'errorCode': 'TASK_NOT_PAID',
          'message': '任务尚未支付，支付后将进入接单大厅',
        });
      }
      if (options.uri.path == '/rider/square') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'tasks': [
              {
                'id': 1,
                'taskNum': 'T20260912-001',
                'taskName': '已支付任务 1',
                'userId': 7,
                'taskType': 'AERIAL_PHOTO',
                'taskStatus': 'IDLE',
                'totalAmount': 120,
                'totalDistance': 3200,
                'description': '大厅可见的已支付任务',
                'createTime': '2026-09-12T10:00:00',
                'updateTime': '2026-09-12T10:00:00',
              },
            ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': 1,
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: await buildOverrides(adapter),
        child: const MaterialApp(home: TaskHallPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('已支付任务 1'), findsOneWidget);

    // 立即接单 → 确认 → 服务端 400 TASK_NOT_PAID → 明确提示
    await tester.tap(find.text('立即接单'));
    await tester.pumpAndSettle();
    expect(find.text('确认接单'), findsOneWidget);

    await tester.tap(find.text('确定接单'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('任务尚未支付，支付后将进入接单大厅'),
      findsOneWidget,
      reason: 'accept 失败应透传服务端明确提示（t22 错误码语义）',
    );

    // 清理 SnackBar 定时器
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
