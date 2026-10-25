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
        'data': options.uri.path == '/dispatch/orders' ? [] : null,
      }),
    );
    expect(tester.takeException(), isNull);
    for (final label in ['我的', '首页']) {
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
      expect(
        tester.takeException(),
        isNull,
        reason: '$label should not overflow',
      );
    }
  });
}
