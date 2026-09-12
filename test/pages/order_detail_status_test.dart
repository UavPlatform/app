// 任务详情页订单状态展示（t29③：orderStatus 不再仅用于确认按钮显隐）。

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

  StubAdapter taskDetailAdapter(Map<String, dynamic> task) {
    return StubAdapter((options) async {
      if (options.uri.path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': task,
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
  }

  testWidgets('待支付订单：任务详情展示订单状态行与去支付入口', (tester) async {
    final overrides = await buildOverrides(taskDetailAdapter({
      'id': 1,
      'taskNum': 'T20260912-001',
      'taskName': '航拍任务',
      'userId': 7,
      'taskType': 'AERIAL_PHOTO',
      'taskStatus': 'IDLE',
      'orderNum': 'ORD-1',
      'totalAmount': 128.5,
      'orderStatus': 'PENDING',
      'createTime': '2026-09-12T10:00:00',
      'updateTime': '2026-09-12T10:00:00',
    }));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: OrderDetailPage(taskNum: 'T20260912-001')),
      ),
    );
    await tester.pumpAndSettle();

    // 订单状态行真实展示（不再仅驱动按钮显隐）
    expect(find.text('订单状态'), findsOneWidget);
    expect(find.text('待支付'), findsOneWidget);
    expect(find.text('订单号'), findsOneWidget);
    expect(find.text('ORD-1'), findsOneWidget);

    // 待支付 → 底部「去支付」入口 + 删除任务
    expect(find.text('去支付'), findsOneWidget);
    expect(find.text('删除任务'), findsOneWidget);
  });

  testWidgets('已支付订单：状态行展示已支付且无支付入口', (tester) async {
    final overrides = await buildOverrides(taskDetailAdapter({
      'id': 2,
      'taskNum': 'T20260912-002',
      'taskName': '测绘任务',
      'userId': 7,
      'taskType': 'SURVEY',
      'taskStatus': 'IDLE',
      'orderNum': 'ORD-2',
      'totalAmount': 66,
      'orderStatus': 'PAID',
      'createTime': '2026-09-12T10:00:00',
      'updateTime': '2026-09-12T10:00:00',
    }));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: OrderDetailPage(taskNum: 'T20260912-002')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('订单状态'), findsOneWidget);
    expect(find.text('已支付'), findsOneWidget);
    expect(find.text('去支付'), findsNothing, reason: '已支付订单不展示支付入口');
    expect(find.text('删除任务'), findsOneWidget);
  });

  testWidgets('待验收订单：状态行展示待验收', (tester) async {
    final overrides = await buildOverrides(taskDetailAdapter({
      'id': 3,
      'taskNum': 'T20260912-003',
      'taskName': '巡检任务',
      'userId': 7,
      'taskType': 'MONITORING',
      'taskStatus': 'IN_PROGRESS',
      'orderNum': 'ORD-3',
      'totalAmount': 88,
      'orderStatus': 'WAITING_CONFIRM',
      'riderName': '飞手甲',
      'createTime': '2026-09-12T10:00:00',
      'updateTime': '2026-09-12T10:00:00',
    }));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: OrderDetailPage(taskNum: 'T20260912-003')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('订单状态'), findsOneWidget);
    expect(find.text('待验收'), findsOneWidget);
    // 待验收 → 底部确认完成按钮（原有语义保留）

    expect(find.text('确认完成'), findsOneWidget);
  });
}
