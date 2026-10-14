// 飞手「我的」页「关于飞翼通」文案边界（REQ-APP-001）：
// ADR-0002 飞行执行在 djifly，App 内不出现「执飞」；ADR-0003 平台统一计价、不议价。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/pilot/pilot_profile_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../../test_support.dart';

void main() {
  testWidgets('关于飞翼通：飞行执行指向 djifly，不出现「执飞」与议价表述', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/rider/stats') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {'todayOrders': 1, 'totalCompleted': 3, 'totalEarnings': 264.65},
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 5),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(HttpClient(TokenStorage(prefs), adapter: adapter)),
      ],
      child: const MaterialApp(home: PilotProfilePage()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('关于飞翼通'));
    await tester.pumpAndSettle();

    expect(find.textContaining('在 djifly 中执行飞行'), findsOneWidget);
    expect(find.textContaining('执飞'), findsNothing, reason: 'ADR-0002：App 不执行飞行');
    expect(find.textContaining('议价'), findsNothing, reason: 'ADR-0003：不议价');
  });
}
