// 飞手「我的」页「关于飞翼通」文案边界（REQ-APP-001）：
// ADR-0002 飞行执行在 djifly，App 内不出现「执飞」；ADR-0003 平台统一计价、不议价。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/pilot/pilot_profile_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import 'package:uav_pilot_app/theme/app_theme.dart';
import '../../test_support.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'pilot profile keeps all destinations and logout usable on a narrow screen dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final username = dark ? '飞手端的超长用户名称与驾驶员姓名测试' : 'test1';
        SharedPreferences.setMockInitialValues({
          'jwt_token': makeJwt(userId: 5, role: 1, username: username),
        });
        final prefs = await SharedPreferences.getInstance();
        final router = GoRouter(
          initialLocation: '/pilot/profile',
          routes: [
            GoRoute(
              path: '/pilot/profile',
              builder: (_, _) => const PilotProfilePage(),
            ),
            GoRoute(
              path: '/pilot/info',
              builder: (_, _) => const Scaffold(body: Text('飞手资料目标')),
            ),
            GoRoute(
              path: '/pilot/equipment',
              builder: (_, _) => const Scaffold(body: Text('租借目标')),
            ),
            GoRoute(
              path: '/pilot/jobs',
              builder: (_, _) => const Scaffold(body: Text('订单目标')),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('登录目标')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(username), findsOneWidget);
        expect(find.text('我的'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('飞手资料'));
        await tester.pumpAndSettle();
        expect(find.text('飞手资料目标'), findsOneWidget);
        expect(router.canPop(), isTrue);
        router.pop();
        await tester.pumpAndSettle();
        await tester.tap(find.text('无人机租借'));
        await tester.pumpAndSettle();
        expect(find.text('租借目标'), findsOneWidget);
        expect(router.canPop(), isFalse);
        router.go('/pilot/profile');
        await tester.pumpAndSettle();
        await tester.tap(find.text('我的订单'));
        await tester.pumpAndSettle();
        expect(find.text('订单目标'), findsOneWidget);
        expect(router.canPop(), isTrue);
        router.go('/pilot/profile');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('飞手资料与驾驶资质'));
        await tester.tap(find.text('飞手资料与驾驶资质'));
        await tester.pumpAndSettle();
        expect(find.text('飞手资料目标'), findsOneWidget);
        expect(router.canPop(), isTrue);
        router.pop();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('退出登录'));
        await tester.tap(find.text('退出登录'));
        await tester.pumpAndSettle();
        expect(find.text('登录目标'), findsOneWidget);
        expect(prefs.getString('jwt_token'), isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('关于飞翼通：飞行执行指向 djifly，不出现「执飞」与议价表述', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/rider/stats') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'todayOrders': 1,
            'totalCompleted': 3,
            'totalEarnings': 264.65,
          },
        });
      }
      return jsonResponse(200, {'success': false, 'message': 'stub'});
    });
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 5),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          httpClientProvider.overrideWithValue(
            HttpClient(TokenStorage(prefs), adapter: adapter),
          ),
        ],
        child: const MaterialApp(home: PilotProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('关于飞翼通'));
    await tester.pumpAndSettle();

    expect(find.textContaining('在 djifly 中执行飞行'), findsOneWidget);
    expect(
      find.textContaining('执飞'),
      findsNothing,
      reason: 'ADR-0002：App 不执行飞行',
    );
    expect(find.textContaining('议价'), findsNothing, reason: 'ADR-0003：不议价');
  });
}
