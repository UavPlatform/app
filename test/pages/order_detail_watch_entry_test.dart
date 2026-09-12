// 任务详情「观看直播」入口测试（t38①：直播运行中显示，未运行/未接单隐藏）。

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
    String taskStatus = 'IN_PROGRESS',
    int? riderId = 8,
    String riderName = '飞手甲',
    String orderStatus = 'PAID',
    String? deviceId = 'UAV-001',
    String liveState = 'RUNNING',
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
      'deviceId': deviceId,
      'liveState': liveState,
      'riderId': riderId,
      'riderName': riderName,
      'createTime': '2026-09-12T10:00:00',
      'updateTime': '2026-09-12T10:00:00',
    };
  }

  StubAdapter detailAdapter(Map<String, dynamic> task) {
    return StubAdapter((options) async {
      if (options.uri.path == '/task/detail') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': task});
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
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

  Widget buildPage(List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: OrderDetailPage(taskNum: 'T20260912-001'),
      ),
    );
  }

  testWidgets('直播运行中 + 已接单任务：显示「观看直播」入口', (tester) async {
    await tester.pumpWidget(
      buildPage(
        await buildOverrides(detailAdapter(taskJson())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('观看直播'), findsOneWidget);
    expect(find.text('联系飞手'), findsOneWidget);
    expect(find.text('订单状态'), findsOneWidget);
  });

  testWidgets('设备未直播：不显示「观看直播」入口', (tester) async {
    await tester.pumpWidget(
      buildPage(
        await buildOverrides(
          detailAdapter(taskJson(liveState: 'IDLE')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('观看直播'), findsNothing);
    expect(find.text('联系飞手'), findsOneWidget);
  });

  testWidgets('未接单任务不显示入口（即便有设备在直播）', (tester) async {
    await tester.pumpWidget(
      buildPage(
        await buildOverrides(
          detailAdapter(
            taskJson(
              taskStatus: 'IDLE',
              riderId: null,
              riderName: '',
              orderStatus: 'PENDING',
              deviceId: 'UAV-001',
              liveState: 'RUNNING',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('观看直播'), findsNothing, reason: '任务无飞手接单，无对应作业直播');
    expect(find.text('去支付'), findsOneWidget);
  });
}
