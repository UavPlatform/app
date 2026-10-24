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
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../dispatch_test_support.dart';
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
            onPressed: () => context.pop('28.123456,113.654321'),
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

void main() {
  testWidgets(
    'compact cargo keeps packaging above the fixed footer at phone size',
    (tester) async {
      tester.view.physicalSize = const Size(400, 890);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showDraft(
        tester,
        WaybillDraft(fields: validCargo()),
        theme: AppTheme.lightTheme,
      );
      final packaging = find.byKey(const ValueKey('packaging'));
      final nextButton = find.byKey(const ValueKey('waybill-next'));
      expect(
        tester.getBottomLeft(packaging).dy,
        lessThan(tester.getTopLeft(nextButton).dy),
      );
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
      );
      expect(find.text('保存草稿'), findsOneWidget);
      expect(find.byTooltip('我的派单运单'), findsNothing);
      expect(find.byTooltip('账号草稿'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quantity stepper and typing share the original count binding and validation',
    (tester) async {
      final container = await showDraft(
        tester,
        WaybillDraft(fields: validCargo()),
        theme: AppTheme.lightTheme,
      );
      await tester.ensureVisible(find.byTooltip('增加件数'));
      await tester.tap(find.byTooltip('增加件数'));
      await tester.pumpAndSettle();
      expect(container.read(waybillDraftProvider).draft.value('count'), '3');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('count')))
            .controller!
            .text,
        '3',
      );
      await tester.enterText(find.byKey(const ValueKey('count')), '7');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('减少件数'));
      await tester.pumpAndSettle();
      expect(container.read(waybillDraftProvider).draft.value('count'), '6');
      await tester.enterText(find.byKey(const ValueKey('count')), '1.5');
      await tester.pumpAndSettle();
      expect(
        container.read(waybillDraftProvider).draft.errorsFor(0),
        contains('count'),
      );
      container
          .read(waybillDraftProvider.notifier)
          .restore(WaybillDraft(fields: {...validCargo(), 'count': '9'}));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('count')))
            .controller!
            .text,
        '9',
      );
      expect(tester.takeException(), isNull);
    },
  );

  // REQ-SHIP-PUB-002: use the production button themes, including full-width
  // outlined buttons, so horizontal footer layout failures cannot be hidden.
  for (final dark in [false, true]) {
    for (var step = 0; step < WaybillDraft.steps.length; step++) {
      testWidgets('real theme dark=$dark lays out draft step $step', (
        tester,
      ) async {
        await showDraft(
          tester,
          WaybillDraft(step: step),
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        );
        expect(tester.takeException(), isNull);
        final next = find.byKey(const ValueKey('waybill-next'));
        expect(tester.getSize(next).width, greaterThan(0));
        if (step > 0) {
          expect(tester.getSize(find.byTooltip('上一步')).width, greaterThan(0));
          await tester.tap(find.byTooltip('上一步'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  testWidgets('review separates authoritative amounts without adding a total', (
    tester,
  ) async {
    await showDraft(tester, WaybillDraft(step: 4));
    expect(find.text('下单定金：¥125.50（结算时抵扣）'), findsOneWidget);
    expect(find.text('飞手服务费：¥180.50/单'), findsOneWidget);
    expect(find.textContaining('¥306.00'), findsNothing);
  });

  testWidgets('settings failure offers retry and no hardcoded amount', (
    tester,
  ) async {
    await showDraft(tester, WaybillDraft(step: 4), failSettings: true);
    expect(find.text('平台金额暂时无法获取'), findsOneWidget);
    expect(find.text('重新获取金额'), findsOneWidget);
    expect(find.textContaining('¥100'), findsNothing);
  });

  testWidgets(
    'account restore confirms replacement and refreshes same-step fields',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
      );
      addTearDown(() => client.dio.close());
      final api = FakeDispatchApi(client)
        ..remote = AccountWaybillDraft(
          draft: WaybillDraft(
            fields: {...validCargo(), 'weightMin': '77'},
            step: 0,
          ),
          revision: 1,
        );
      final container = await showDraft(
        tester,
        WaybillDraft(fields: {...validCargo(), 'weightMin': 'bad'}),
        dispatchApi: api,
        accountActions: true,
      );
      await next(tester);
      expect(find.text('重量下限须为大于 0 的数字'), findsOneWidget);
      await tester.tap(find.byTooltip('账号草稿'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('恢复账号草稿'));
      await tester.pumpAndSettle();
      expect(
        container.read(waybillDraftProvider).draft.value('weightMin'),
        'bad',
      );
      await tester.tap(find.text('恢复草稿'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('weightMin')))
            .initialValue,
        '77',
      );
      expect(
        container.read(waybillDraftProvider).draft.value('weightMin'),
        '77',
      );
      expect(api.saveCalls, 0);
      expect(find.text('重量下限须为大于 0 的数字'), findsNothing);
    },
  );

  testWidgets(
    'invalid restored appointment displays an editable picker without crashing',
    (tester) async {
      await showDraft(
        tester,
        WaybillDraft(
          fields: {'timeMode': 'scheduled', 'scheduledAt': 'bad'},
          step: 3,
        ),
      );
      expect(find.text('选择预约日期与时间'), findsOneWidget);
      await next(tester);
      expect(find.text('请选择未来的预约时间'), findsOneWidget);
    },
  );

  testWidgets(
    'missing cargo cannot advance; hazardous category is unavailable',
    (tester) async {
      final container = await showDraft(tester, WaybillDraft());
      expect(find.text('危险品 · 暂不开放'), findsOneWidget);
      final hazardous = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '危险品 · 暂不开放'),
      );
      expect(hazardous.onSelected, isNull);
      await next(tester);
      expect(container.read(waybillDraftProvider).draft.step, 0);
      expect(find.text('请选择货物类别'), findsOneWidget);
      expect(find.text('重量下限须为大于 0 的数字'), findsOneWidget);
    },
  );

  testWidgets(
    'validated cargo advances and back navigation restores editable values',
    (tester) async {
      final container = await showDraft(
        tester,
        WaybillDraft(fields: validCargo()),
      );
      await tester.enterText(find.byKey(const ValueKey('weightMin')), '12');
      await next(tester);
      expect(container.read(waybillDraftProvider).draft.step, 1);
      expect(find.byKey(const ValueKey('start.pick')), findsOneWidget);
      await tester.tap(find.byTooltip('上一步'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('weightMin')))
            .initialValue,
        '12',
      );
    },
  );

  testWidgets(
    'map picker updates the correct endpoint and preserves the other',
    (tester) async {
      final container = await showDraft(
        tester,
        WaybillDraft(
          fields: {...validSite('start'), ...validSite('end')},
          step: 2,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('end.pick')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选定终点'));
      await tester.pumpAndSettle();
      final draft = container.read(waybillDraftProvider).draft;
      expect(draft.value('end.lat'), '28.123456');
      expect(draft.value('end.lng'), '113.654321');
      expect(draft.value('start.lat'), '27.8981');
    },
  );

  testWidgets('winch fields are required only when landing is impossible', (
    tester,
  ) async {
    final container = await showDraft(
      tester,
      WaybillDraft(fields: validSite('start'), step: 1),
    );
    await tester.tap(find.text('不能 · 绞盘吊放'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('start.winchMin')), findsOneWidget);
    await next(tester);
    expect(container.read(waybillDraftProvider).draft.step, 1);
    await tester.tap(find.text('能 · 落地放货'));
    await tester.pumpAndSettle();
    await next(tester);
    expect(container.read(waybillDraftProvider).draft.step, 2);
  });

  testWidgets(
    'review saves only a local draft and offers no payment/order action',
    (tester) async {
      await showDraft(
        tester,
        WaybillDraft(
          fields: {
            ...validCargo(),
            ...validSite('start'),
            ...validSite('end'),
            'timeMode': 'now',
          },
          step: 4,
        ),
      );
      expect(find.text('保存运单草稿'), findsOneWidget);
      expect(find.text('支付定金并下单'), findsNothing);
      expect(find.textContaining('200'), findsNothing);
      await next(tester);
      expect(find.text('运单草稿已保存'), findsOneWidget);
    },
  );
}
