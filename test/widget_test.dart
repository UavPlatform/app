import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uav_pilot_app/config/api_config.dart';
import 'package:uav_pilot_app/main.dart';
import 'package:uav_pilot_app/pages/auth/login_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';

/// 构建（未登录态的）真实 App 根组件，注入 mock SharedPreferences。
Future<Widget> buildUnauthenticatedApp() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MyApp(),
  );
}

/// 直接构建登录页（独立 widget 冒烟，不经过路由）。
Future<Widget> buildLoginPage() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: LoginPage()),
  );
}

Future<ElevatedButton> _pumpToLoginPage(WidgetTester tester) async {
  await tester.pumpAndSettle();

  // 跳过引导页 → 登录页
  await tester.tap(find.text('跳过'));
  await tester.pumpAndSettle();
  return tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, '登 录'),
  );
}

void main() {
  group('App 启动冒烟（未登录链路）', () {
    testWidgets('未登录启动直接进入引导页', (tester) async {
      await tester.pumpWidget(await buildUnauthenticatedApp());
      await tester.pump();
      expect(find.text('开始使用飞翼通'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
    });

    testWidgets('引导页跳过后进入登录页，核心控件完整', (tester) async {
      await tester.pumpWidget(await buildUnauthenticatedApp());
      await _pumpToLoginPage(tester);

      expect(find.text('欢迎使用飞翼通'), findsOneWidget);
      expect(find.text('无人机飞手接单平台'), findsOneWidget);
      expect(find.widgetWithText(TextField, '请输入用户名'), findsOneWidget);
      expect(find.widgetWithText(TextField, '请输入密码'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, '登 录'), findsOneWidget);
      expect(find.text('用户注册'), findsOneWidget);
      expect(find.text('飞手注册'), findsOneWidget);
    });

    testWidgets('注册必填与密码不一致提示显示在字段下方', (tester) async {
      await tester.pumpWidget(await buildUnauthenticatedApp());
      await _pumpToLoginPage(tester);
      await tester.ensureVisible(find.text('用户注册'));
      await tester.tap(find.text('用户注册'));
      await tester.pumpAndSettle();

      final submit = find.widgetWithText(ElevatedButton, '注 册');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('密码至少 6 位'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test-user');
      await tester.enterText(fields.at(1), 'password1');
      await tester.enterText(fields.at(2), 'password2');
      await tester.pumpAndSettle();
      expect(find.text('两次密码不一致'), findsOneWidget);
      expect(find.text('密码至少 6 位'), findsNothing);
    });

    testWidgets('单页引导点击立即开始进入登录页', (tester) async {
      await tester.pumpWidget(await buildUnauthenticatedApp());
      await tester.pumpAndSettle();
      expect(find.text('填写起终点与货物信息'), findsOneWidget);
      expect(find.text('查看运单进度'), findsOneWidget);
      await tester.tap(find.text('立即开始'));
      await tester.pumpAndSettle();
      expect(find.text('欢迎使用飞翼通'), findsOneWidget);
    });
  });

  group('登录页核心 widget 冒烟', () {
    testWidgets('空用户名提交被拦截并提示', (tester) async {
      await tester.pumpWidget(await buildLoginPage());

      final loginButton = find.widgetWithText(ElevatedButton, '登 录');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump(); // 触发 SnackBar 入场
      await tester.pump(const Duration(milliseconds: 600)); // 完成入场动画

      expect(find.byType(SnackBar), findsOneWidget);
      // 提示文案位于 SnackBar 内（与输入框 hint 同名，需限定范围）
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('请输入用户名'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('已填用户名但密码为空时提交被拦截并提示', (tester) async {
      await tester.pumpWidget(await buildLoginPage());

      await tester.enterText(
        find.widgetWithText(TextField, '请输入用户名'),
        'smoke_user',
      );
      await tester.pump();

      final loginButton = find.widgetWithText(ElevatedButton, '登 录');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SnackBar), findsOneWidget);
      // 提示文案位于 SnackBar 内（与输入框 hint 同名，需限定范围）
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('请输入密码'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('密码可见性切换：密文 ↔ 明文', (tester) async {
      await tester.pumpWidget(await buildLoginPage());

      final passwordField = find.widgetWithText(TextField, '请输入密码');
      await tester.enterText(passwordField, 'secret123');
      await tester.pump();

      // 初始为密文（眼睛-斜杠图标）
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // 切换为明文（眼睛图标），输入内容保持不变
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
      expect(find.text('secret123'), findsOneWidget);
    });

    testWidgets('服务器设置预填生效地址（新装回落内置默认环境）', (tester) async {
      await tester.pumpWidget(await buildLoginPage());

      expect(find.byKey(const Key('login_server_url')), findsNothing);
      await tester.tap(find.byTooltip('网络环境调试'));
      await tester.pumpAndSettle();

      final serverField = find.byKey(const Key('login_server_url'));
      expect(serverField, findsOneWidget);
      final controller = tester.widget<TextField>(serverField).controller;
      final prefilled = Uri.parse(controller?.text ?? '');
      final defaultUri = Uri.parse(ApiConfig.defaultBaseUrl);
      expect(prefilled.scheme, defaultUri.scheme);
      expect(prefilled.host, defaultUri.host);
      expect(prefilled.port, defaultUri.port);
      expect(
        prefilled.path.replaceAll(RegExp(r'/+$'), ''),
        '',
        reason: '新装首启无本地 serverUrl 时应预填内置默认地址（P1-5）',
      );
    });
  });
}
