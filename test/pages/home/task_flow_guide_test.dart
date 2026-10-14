import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/pages/home/task_flow_guide.dart';
import 'home_page_test.dart' show pumpHome, homeAdapter;

void main() {
  testWidgets(
    'Homepage shows the guide; close is temporary; opt out persists and manual help remains available',
    (tester) async {
      await pumpHome(tester, homeAdapter(), guideDismissed: false);
      expect(find.byType(TaskFlowGuide), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      await tester.tap(find.byTooltip('本次关闭'));
      await tester.pumpAndSettle();
      expect(prefs.getBool(taskFlowGuideDismissedKey), false);
      await tester.tap(find.text('流程指南'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskFlowGuide), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('task-flow-guide-hide')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('task-flow-guide-done')));
      await tester.pumpAndSettle();
      expect(prefs.getBool(taskFlowGuideDismissedKey), true);
      expect(find.byType(TaskFlowGuide), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await pumpHome(tester, homeAdapter());
      expect(find.byType(TaskFlowGuide), findsNothing);
      await tester.tap(find.text('流程指南'));
      await tester.pumpAndSettle();
      expect(find.byType(TaskFlowGuide), findsOneWidget);
      await tester.tap(find.byTooltip('本次关闭'));
      await tester.pumpAndSettle();
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Guide fits a small screen and enlarged text in $brightness; full workflow remains accessible',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showTaskFlowGuide(context, prefs),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('打开'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('验收后结束任务'),
          180,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('task-flow-guide-steps')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('验收后结束任务'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('task-flow-guide-done')));
        await tester.pumpAndSettle();
        expect(prefs.getBool(taskFlowGuideDismissedKey), isNull);
      },
    );
  }
}
