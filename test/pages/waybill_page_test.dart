import 'package:uav_pilot_app/pages/waybill/account_draft_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uav_pilot_app/pages/waybill/waybill_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/providers/dispatch_provider.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/theme/app_theme.dart';

import '../models/waybill_draft_test.dart' show validCargo, validSite;

Future<ProviderContainer> showDraft(
  WidgetTester tester,
  WaybillDraft draft, {
  DispatchApi? dispatchApi,
  bool failSettings = false,
  ThemeData? theme,
  bool accountActions = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final notifier = WaybillDraftNotifier(prefs, 'test-draft')..replace(draft);
  await notifier.save();
  final router = GoRouter(
    initialLocation: '/waybill',
    routes: [
      GoRoute(
        path: '/waybill',
        builder: (_, _) => accountActions
            ? const Scaffold(
                body: WaybillPage(),
                floatingActionButton: AccountDraftActions(),
              )
            : const WaybillPage(),
      ),
      GoRoute(
        path: '/map/pick',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.pop('28.123456,113.654321;地图测试点;测试路88号'),
            child: Text(
              '选定${state.uri.queryParameters['point'] == 'start' ? '起点' : '终点'}',
            ),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dispatchSettingsProvider.overrideWith(
          (ref) async => failSettings
              ? throw const DispatchApiException('offline')
              : const DispatchSettings(
                  currency: 'CNY',
                  depositAmount: 125.50,
                  pilotServiceFee: 180.50,
                  orderingEnabled: false,
                ),
        ),
        if (dispatchApi != null)
          dispatchApiProvider.overrideWithValue(dispatchApi),
        sharedPreferencesProvider.overrideWithValue(prefs),
        waybillDraftScopeProvider.overrideWithValue('test-scope'),
        waybillDraftProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp.router(routerConfig: router, theme: theme),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(WaybillPage)));
}

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('waybill-next')));
  await tester.pumpAndSettle();
}

Future<void> edit(WidgetTester tester, String id) async {
  final row = find.byKey(ValueKey('edit-$id'));
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

Future<void> saveEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('waybill-editor-save')));
  await tester.pumpAndSettle();
}

WaybillDraft completeDraft() => WaybillDraft(
  fields: {
    ...validCargo(),
    ...validSite('start'),
    ...validSite('end'),
    'timeMode': 'now',
  },
);

void main() {
  testWidgets(
    'review fits normal phone height and opens structured bottom-sheet details',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showDraft(
        tester,
        WaybillDraft(
          fields: {
            ...completeDraft().fields,
            'declaredValue': '500',
            'start.notes': '门口联系',
          },
          step: 4,
        ),
        theme: AppTheme.lightTheme,
      );
      expect(
        find.byKey(const ValueKey('review-时间')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, '确认运单，前往模拟支付').hitTestable(),
        findsOneWidget,
      );
      expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .maxScrollExtent,
        0,
      );
      await tester.tap(find.byKey(const ValueKey('review-货物')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('货物详情'), findsOneWidget);
      expect(find.text('货物类别'), findsOneWidget);
      expect(find.text('包装方式'), findsOneWidget);
      expect(find.text('吊点信息'), findsOneWidget);
      expect(find.text('500 元'), findsOneWidget);
      await tester.tap(find.text('我知道了'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('review-起点')));
      await tester.pumpAndSettle();
      expect(find.text('起点详情'), findsOneWidget);
      expect(find.text('门口联系'), findsOneWidget);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('summary shows grouped values without inline text fields', (
    tester,
  ) async {
    await showDraft(tester, completeDraft());
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('10–20 kg'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-start.contact')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-end.contact')), findsOneWidget);
  });
  testWidgets(
    'category closes without committing edits, saves only its own fields',
    (tester) async {
      final container = await showDraft(tester, completeDraft());
      await edit(tester, 'category');
      expect(find.byKey(const ValueKey('weightMin')), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '易碎'));
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(
        container.read(waybillDraftProvider).draft.value('category'),
        '普通',
      );
      await edit(tester, 'category');
      await tester.tap(find.widgetWithText(ChoiceChip, '易碎'));
      await saveEditor(tester);
      expect(
        container.read(waybillDraftProvider).draft.value('category'),
        '易碎',
      );
      expect(
        container.read(waybillDraftProvider).draft.value('start.phone'),
        '13800138000',
      );
      expect(find.text('易碎'), findsOneWidget);
    },
  );
  testWidgets(
    'specification keeps quantity controls and rejects invalid values',
    (tester) async {
      final container = await showDraft(tester, completeDraft());
      await edit(tester, 'specification');
      await tester.ensureVisible(find.byTooltip('增加件数'));
      await tester.tap(find.byTooltip('增加件数'));
      await tester.pumpAndSettle();
      expect(container.read(waybillDraftProvider).draft.value('count'), '2');
      await tester.enterText(find.byKey(const ValueKey('count')), '1.5');
      await saveEditor(tester);
      expect(find.byKey(const ValueKey('waybill-editor-save')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('count')), '4');
      await saveEditor(tester);
      expect(container.read(waybillDraftProvider).draft.value('count'), '4');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('contacts validate phone and edit the correct endpoint', (
    tester,
  ) async {
    final container = await showDraft(tester, completeDraft());
    await edit(tester, 'end.contact');
    expect(find.byKey(const ValueKey('end.site')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('end.phone')), 'bad');
    await saveEditor(tester);
    expect(find.text('请填写有效联系电话'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('end.phone')),
      '13900139000',
    );
    await saveEditor(tester);
    expect(
      container.read(waybillDraftProvider).draft.value('end.phone'),
      '13900139000',
    );
    expect(
      container.read(waybillDraftProvider).draft.value('start.phone'),
      '13800138000',
    );
  });
  testWidgets('map returns into the sheet and commits only after save', (
    tester,
  ) async {
    final container = await showDraft(tester, completeDraft());
    await edit(tester, 'end.location');
    await tester.tap(find.byKey(const ValueKey('end.pick')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选定终点'));
    await tester.pumpAndSettle();
    expect(
      container.read(waybillDraftProvider).draft.value('end.lat'),
      '27.8981',
    );
    await saveEditor(tester);
    expect(
      container.read(waybillDraftProvider).draft.value('end.lat'),
      '28.123456',
    );
    final saved = container.read(waybillDraftProvider).draft;
    expect(saved.value('end.place'), '地图测试点');
    expect(saved.value('end.placeAddress'), '测试路88号');
    expect(saved.cloudFields.containsKey('end.place'), isFalse);
    expect(saved.cloudFields.containsKey('end.placeAddress'), isFalse);
    expect(find.text('地图测试点'), findsOneWidget);
    expect(
      container.read(waybillDraftProvider).draft.value('start.lat'),
      '27.8981',
    );
  });
  testWidgets(
    'site conditions require winch heights only when landing is impossible',
    (tester) async {
      final container = await showDraft(tester, completeDraft());
      await edit(tester, 'start.conditions');
      await tester.tap(find.text('不能 · 绞盘吊放'));
      await tester.pumpAndSettle();
      await saveEditor(tester);
      expect(find.byKey(const ValueKey('start.winchMin')), findsOneWidget);
      expect(
        container.read(waybillDraftProvider).draft.value('start.landing'),
        'yes',
      );
      await tester.tap(find.text('能 · 落地放货'));
      await tester.pumpAndSettle();
      await saveEditor(tester);
      expect(find.byKey(const ValueKey('waybill-editor-save')), findsNothing);
    },
  );
  testWidgets(
    'appointment reuses project wheel pickers and commits only on save',
    (tester) async {
      final scheduled = DateTime.now().add(const Duration(days: 2));
      final stamp = scheduled.toIso8601String();
      final container = await showDraft(
        tester,
        WaybillDraft(
          fields: {
            ...completeDraft().fields,
            'timeMode': 'scheduled',
            'scheduledAt': stamp,
          },
        ),
      );
      await edit(tester, 'time');
      final label = stamp.replaceAll('T', ' ').substring(0, 16);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('选择日期'), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byType(ListWheelScrollView), findsNWidgets(3));
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(
        container.read(waybillDraftProvider).draft.value('scheduledAt'),
        stamp,
      );
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(find.text('选择时间'), findsOneWidget);
      expect(find.byType(TimePickerDialog), findsNothing);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(
        container.read(waybillDraftProvider).draft.value('scheduledAt'),
        stamp,
      );
      await saveEditor(tester);
      final saved = DateTime.parse(
        container.read(waybillDraftProvider).draft.value('scheduledAt'),
      );
      expect(saved.year, scheduled.year);
      expect(saved.month, scheduled.month);
      expect(saved.day, scheduled.day);
      expect(saved.hour, scheduled.hour);
      expect(saved.minute, scheduled.minute);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('invalid appointment remains editable in its own sheet', (
    tester,
  ) async {
    await showDraft(
      tester,
      WaybillDraft(fields: {'timeMode': 'scheduled', 'scheduledAt': 'bad'}),
    );
    await edit(tester, 'time');
    expect(find.text('选择预约日期与时间'), findsOneWidget);
    await saveEditor(tester);
    expect(find.text('请选择未来的预约时间'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'confirm opens the first invalid group instead of bypassing validation',
    (tester) async {
      final container = await showDraft(tester, WaybillDraft());
      await next(tester);
      expect(find.widgetWithText(ChoiceChip, '普通'), findsOneWidget);
      await saveEditor(tester);
      expect(find.text('请选择货物类别'), findsWidgets);
      expect(container.read(waybillDraftProvider).draft.step, 0);
    },
  );
  testWidgets(
    'valid summary reaches review, amounts stay authoritative and can return to edit',
    (tester) async {
      await showDraft(tester, completeDraft());
      await next(tester);
      expect(find.text('¥125.50'), findsOneWidget);
      expect(find.text('¥180.50/单'), findsOneWidget);
      expect(find.textContaining('¥306.00'), findsNothing);
      await tester.tap(find.byTooltip('上一步'));
      await tester.pumpAndSettle();
      await edit(tester, 'lifting');
      expect(find.byKey(const ValueKey('lifting')), findsOneWidget);
      expect(find.byKey(const ValueKey('category')), findsNothing);
    },
  );
  testWidgets(
    'restoring another draft closes the editor without overwriting restored values',
    (tester) async {
      final container = await showDraft(tester, completeDraft());
      await edit(tester, 'category');
      await tester.tap(find.widgetWithText(ChoiceChip, '易碎'));
      container
          .read(waybillDraftProvider.notifier)
          .restore(WaybillDraft(fields: {...validCargo(), 'category': '冷链'}));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('waybill-editor-save')), findsNothing);
      expect(
        container.read(waybillDraftProvider).draft.value('category'),
        '冷链',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('photos have a dedicated editor and empty-state summary', (
    tester,
  ) async {
    await showDraft(tester, completeDraft());
    await edit(tester, 'cargo.photos');
    expect(find.text('照片（选填）'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await saveEditor(tester);
    expect(find.byKey(const ValueKey('waybill-editor-save')), findsNothing);
  });
  for (final dark in [false, true]) {
    testWidgets('narrow summary and editor layout dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showDraft(
        tester,
        completeDraft(),
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      );
      await edit(tester, 'specification');
      expect(tester.takeException(), isNull);
      await saveEditor(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
