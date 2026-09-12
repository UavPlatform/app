// App 启动冒烟测试（替换 counter 模板测试，修复 QA-A1）。
//
// 覆盖真实启动链路与核心 widget：
//   1. 未登录启动：启动页渲染品牌信息 → 2 秒后自动进入引导页；
//   2. 引导页跳过 → 登录页，核心控件（输入框/登录按钮/注册入口）完整；
//   3. 引导页「下一步」翻页至末页「立即开始」→ 登录页；
//   4. 登录表单校验：空用户名/空密码提交的拦截提示；
//   5. 密码明文/密文切换；
//   6. 服务器设置预填生效地址（新装回落内置默认环境，P1-5）。
//
// 说明：启动链路（未登录）不触发网络请求，仅依赖本地 SharedPreferences，
// 测试中通过 setMockInitialValues 注入空配置，保证结果确定性。

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
  // 越过启动页 2 秒延时，自动进入引导页
  await tester.pump(const Duration(seconds: 2));
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
    testWidgets('启动页渲染品牌信息并自动进入引导页', (tester) async {
      await tester.pumpWidget(await buildUnauthenticatedApp());

      // 启动页关键内容
      expect(find.text('飞翼通'), findsOneWidget);
      expect(find.text('无人机服务平台'), findsOneWidget);
      expect(find.byIcon(Icons.flight), findsOneWidget);

      // 2 秒后自动进入引导页（首页文案「一键发布任务」+ 跳过按钮）
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('一键发布任务'), findsOneWidget);
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

    testWidgets('引导页逐页翻至末页，点击「立即开始」进入登录页', (tester) async {
      await tester.pumpWidget(await buildUnauthenticatedApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // 第一页 → 第二页
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('专业团队服务'), findsOneWidget);

      // 第二页 → 第三页（末页，按钮文案变为「立即开始」）
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('实时跟踪进度'), findsOneWidget);
      expect(find.text('立即开始'), findsOneWidget);
      expect(find.text('下一步'), findsNothing);

      // 立即开始 → 登录页
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

      // 展开「服务器设置」
      await tester.tap(find.text('服务器设置'));
      await tester.pump();

      final serverField = find.widgetWithText(
        TextField,
        '请输入服务器地址，如 http://192.168.1.1:8080',
      );
      expect(serverField, findsOneWidget);
      final controller = tester.widget<TextField>(serverField).controller;
      expect(
        controller?.text,
        ApiConfig.defaultBaseUrl,
        reason: '新装首启无本地 serverUrl 时应预填内置默认地址（P1-5）',
      );
    });
  });
}
