import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/widgets/app_bottom_nav.dart';
import '../routes/user_shell_route_test.dart' show pumpLoggedInApp;
import '../test_support.dart';

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });
  testWidgets('Customer pages fit a narrow phone and increased text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpLoggedInApp(
      tester,
      handler: (options) async => jsonResponse(200, {
        'success': true,
        'data': options.uri.path == '/order/list'
            ? {
                'orders': [
                  {
                    'orderNum': 'ORD-1',
                    'taskName': '设备吊运',
                    'totalAmount': 128.5,
                    'orderStatus': 0,
                  },
                ],
                'currentPage': 0,
                'totalPages': 1,
                'totalElements': 1,
              }
            : options.uri.path == '/task/list'
            ? {
                'tasks': [
                  {
                    'id': 1,
                    'userId': 7,
                    'taskNum': 'TASK-1',
                    'taskName': '设备吊运',
                    'taskType': 'TRANSPORT',
                    'taskStatus': 'IDLE',
                    'orderNum': 'ORD-1',
                    'scheduledTime': '2026-10-03 16:30:00',
                    'cargoCategory': 'EQUIPMENT',
                    'cargoWeightKg': 120.0,
                    'riderName': '张师傅',
                    'actionHint': '请确认订单后支付',
                  },
                ],
                'currentPage': 0,
                'totalPages': 1,
                'totalElements': 1,
              }
            : null,
      }),
    );
    expect(tester.takeException(), isNull);
    for (final label in ['订单', '我的']) {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.text(label),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (label == '订单') {
        expect(find.text('2026-10-03 16:30:00'), findsOneWidget);
        expect(find.text('设备 · 120.0 kg'), findsOneWidget);
        expect(find.text('张师傅'), findsOneWidget);
        expect(find.text('请确认订单后支付'), findsOneWidget);
      }
      expect(
        tester.takeException(),
        isNull,
        reason: '$label should not overflow',
      );
    }
  });
}
