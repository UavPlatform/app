import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/pages/profile/profile_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';

void main() {
  testWidgets('「我的」页不展示无响应菜单项，关于我们可打开', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1000));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: Scaffold(body: ProfilePage())),
    ));
    await tester.pump();
    expect(find.text('联系客服'), findsNothing);
    expect(find.text('帮助与反馈'), findsNothing);
    expect(find.text('设置'), findsNothing);
    await tester.tap(find.text('关于我们'));
    await tester.pumpAndSettle();
    expect(find.textContaining('无人机吊运撮合平台'), findsOneWidget);
    // ADR-0003：平台统一计价、不议价
    expect(find.textContaining('平台按距离、重量与机型统一计价'), findsOneWidget);
    expect(find.textContaining('报价'), findsNothing);
    expect(find.textContaining('议价'), findsNothing);
  });
}
