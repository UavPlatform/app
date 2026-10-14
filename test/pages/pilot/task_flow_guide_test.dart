import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/home/task_flow_guide.dart';
import 'package:uav_pilot_app/pages/pilot/task_hall_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../../test_support.dart';

void main() {
  testWidgets(
    'Pilot guide appears independently of customer opt-out and can be hidden or reopened',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        taskFlowGuideDismissedKey: true,
        'jwt_token': makeJwt(userId: 8, role: 1),
        'server_url': 'http://stub.local:8081',
      });
      final prefs = await SharedPreferences.getInstance();
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter(
          (_) async => jsonResponse(200, {'success': false, 'message': 'stub'}),
        ),
      );
      Future<void> pumpHall() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              httpClientProvider.overrideWithValue(client),
            ],
            child: const MaterialApp(home: TaskHallPage()),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpHall();
      expect(find.text('新手指南 · 飞手作业'), findsOneWidget);
      expect(find.text('知道了，开始发布'), findsNothing);
      await tester.tap(find.byTooltip('本次关闭'));
      await tester.pumpAndSettle();
      expect(prefs.getBool(pilotTaskFlowGuideDismissedKey), isNull);
      await tester.tap(find.text('流程指南'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-flow-guide-hide')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('知道了，去看任务'));
      await tester.pumpAndSettle();
      expect(prefs.getBool(pilotTaskFlowGuideDismissedKey), true);
      expect(prefs.getBool(taskFlowGuideDismissedKey), true);
      await tester.pumpWidget(const SizedBox());
      await pumpHall();
      expect(find.byType(TaskFlowGuide), findsNothing);
      await tester.tap(find.text('流程指南'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskFlowGuide), findsOneWidget);
      await tester.tap(find.byTooltip('本次关闭'));
      await tester.pumpAndSettle();
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('Pilot workflow fits small screens in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(body: TaskFlowGuide(isPilot: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('交付成果，等待用户验收'),
        180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('task-flow-guide-steps')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('交付成果，等待用户验收'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
