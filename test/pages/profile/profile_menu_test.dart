import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/pages/profile/profile_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/theme/app_theme.dart';
import '../../test_support.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'narrow profile handles long usernames, larger text and unchanged navigation dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'jwt_token': makeJwt(username: '运输调度中心的超长用户名称测试'),
          'dark_mode': dark,
        });
        final prefs = await SharedPreferences.getInstance();
        final router = GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
            GoRoute(
              path: '/orders/history',
              builder: (_, _) => const Scaffold(body: Text('历史订单目标')),
            ),
            GoRoute(
              path: '/drafts',
              builder: (_, _) => const Scaffold(body: Text('草稿箱目标')),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('登录页面')),
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
        expect(find.text('运输调度中心的超长用户名称测试'), findsOneWidget);
        expect(find.text('业务与服务'), findsOneWidget);
        expect(find.text('业务服务'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('历史订单'));
        await tester.tap(find.text('历史订单'));
        await tester.pumpAndSettle();
        expect(find.text('历史订单目标'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('草稿箱'));
        await tester.tap(find.text('草稿箱'));
        await tester.pumpAndSettle();
        expect(find.text('草稿箱目标'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('退出登录'));
        await tester.tap(find.text('退出登录'));
        await tester.pumpAndSettle();
        expect(find.text('登录页面'), findsOneWidget);
        expect(prefs.getString('jwt_token'), isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('「我的」页不展示无响应菜单项，关于飞翼通可打开', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 1000));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: Scaffold(body: ProfilePage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('联系客服'), findsNothing);
    expect(find.text('帮助与反馈'), findsNothing);
    expect(find.text('设置'), findsNothing);
    expect(find.text('我的评价'), findsNothing);
    expect(find.text('订单与任务'), findsNothing);
    expect(find.text('地址管理'), findsNothing);
    expect(find.text('历史订单'), findsOneWidget);
    expect(find.text('草稿箱'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);

    await tester.tap(find.text('关于飞翼通'));
    await tester.pumpAndSettle();
    expect(find.textContaining('无人机吊运撮合平台'), findsOneWidget);
    expect(find.textContaining('平台按距离、重量与机型统一计价'), findsOneWidget);
    expect(find.textContaining('报价'), findsNothing);
    expect(find.textContaining('议价'), findsNothing);
  });
}
