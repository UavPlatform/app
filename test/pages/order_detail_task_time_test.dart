// 任务详情页展示任务时间（t19 验收：详情页显示发布所选时间）。

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
  Future<ProviderScope> buildPage({
    required Map<String, Object> prefsValues,
    required StubAdapter adapter,
    required Widget child,
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(
          HttpClient(TokenStorage(prefs), adapter: adapter),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('详情页展示发布所选的任务时间', (tester) async {
    final adapter = StubAdapter((options) async {
      if (options.uri.path.contains('/task/detail')) {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'id': 1,
            'taskNum': 'T20260911-001',
            'taskName': '航拍任务',
            'userId': 7,
            'taskType': 'AERIAL_PHOTO',
            'taskStatus': 'IDLE',
            'taskTime': '2026-09-15 14:30:00',
            'createTime': '2026-09-11T20:00:00',
            'updateTime': '2026-09-11T20:00:00',
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    final scope = await buildPage(
      prefsValues: const {'server_url': 'http://stub.local:8081'},
      adapter: adapter,
      child: const OrderDetailPage(taskNum: 'T20260911-001'),
    );
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    // 任务信息区出现「任务时间」行，值为发布所选时间（截断到分钟展示）
    expect(find.text('任务时间'), findsOneWidget);
    expect(find.text('2026-09-15 14:30'), findsOneWidget);
    // 既有信息行不受影响
    expect(find.text('任务编号'), findsOneWidget);
    expect(find.text('T20260911-001'), findsOneWidget);
  });

  testWidgets('taskTime 为 null（旧数据/未选时间）不展示任务时间行', (tester) async {
    final adapter = StubAdapter((options) async {
      if (options.uri.path.contains('/task/detail')) {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'id': 2,
            'taskNum': 'T20260911-002',
            'taskName': '测绘任务',
            'userId': 7,
            'taskType': 'SURVEY',
            'taskStatus': 'IDLE',
            'createTime': '2026-09-11T20:00:00',
            'updateTime': '2026-09-11T20:00:00',
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });

    final scope = await buildPage(
      prefsValues: const {'server_url': 'http://stub.local:8081'},
      adapter: adapter,
      child: const OrderDetailPage(taskNum: 'T20260911-002'),
    );
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    expect(find.text('任务时间'), findsNothing);
    expect(find.text('测绘任务'), findsOneWidget);
  });
}
