import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uav_pilot_app/pages/profile/draft_box_page.dart';
import 'package:uav_pilot_app/pages/waybill/waybill_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';

void main() {
  testWidgets(
    'draft box opens, creates and deletes drafts without replacing siblings',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = WaybillDraftNotifier(prefs, 'draft-box-test');
      notifier.replace(WaybillDraft(fields: {'start.site': '第一份'}));
      final first = notifier.state.activeId!;
      await notifier.createDraft();
      notifier.update('start.site', '第二份');
      await notifier.save();
      final router = GoRouter(
        initialLocation: '/drafts',
        routes: [
          GoRoute(path: '/drafts', builder: (_, _) => const DraftBoxPage()),
          GoRoute(path: '/waybill/new', builder: (_, _) => const WaybillPage()),
          GoRoute(path: '/home', builder: (_, _) => const Scaffold()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            waybillDraftScopeProvider.overrideWithValue('scope'),
            waybillDraftProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('第一份 → 待选终点'), findsOneWidget);
      expect(find.text('第二份 → 待选终点'), findsOneWidget);
      await tester.tap(find.text('第一份 → 待选终点'));
      await tester.pumpAndSettle();
      expect(find.byType(WaybillPage), findsOneWidget);
      expect(notifier.state.activeId, first);
      expect(notifier.state.draft.value('start.site'), '第一份');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建草稿'));
      await tester.pumpAndSettle();
      expect(notifier.state.entries.length, 3);
      expect(notifier.state.draft.fields, isEmpty);
      final blank = notifier.state.activeId!;
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(ValueKey('draft-$blank')),
          matching: find.byTooltip('删除草稿'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();
      expect(notifier.state.entries.length, 2);
      expect(notifier.state.activeId, first);
      router.push('/waybill/new');
      await tester.pumpAndSettle();
      expect(notifier.state.draft.value('start.site'), '第一份');
      expect(tester.takeException(), isNull);
    },
  );
}
