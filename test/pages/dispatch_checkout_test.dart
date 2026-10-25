import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_checkout_card.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_order_pages.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../dispatch_order_test_support.dart';
import '../models/waybill_draft_test.dart' show validCargo, validSite;

Future<({ProviderContainer container, FakeDispatchOrderApi api})> setup(
  WidgetTester tester, {
  bool enabled = true,
  bool prohibited = false,
  bool loseResponse = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final client = HttpClient(TokenStorage(prefs));
  addTearDown(() => client.dio.close());
  final api = FakeDispatchOrderApi(client)
    ..enabled = enabled
    ..prohibited = prohibited
    ..loseCreateResponse = loseResponse;
  final notifier = WaybillDraftNotifier(prefs, 'checkout-draft')
    ..replace(
      WaybillDraft(
        step: 4,
        fields: {
          ...validCargo(),
          ...validSite('start'),
          ...validSite('end'),
          'timeMode': 'now',
        },
      ),
    );
  await notifier.save();
  final router = GoRouter(
    initialLocation: '/checkout',
    routes: [
      GoRoute(
        path: '/checkout',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(
            child: Consumer(
              builder: (_, ref, _) => DispatchCheckoutCard(
                draft: ref.watch(waybillDraftProvider).draft,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/dispatch/orders',
        builder: (_, _) => const DispatchOrderListPage(),
      ),
      GoRoute(
        path: '/dispatch/orders/:orderId',
        builder: (_, state) =>
            DispatchOrderPage(orderId: state.pathParameters['orderId']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        waybillDraftScopeProvider.overrideWithValue('checkout-scope'),
        waybillDraftProvider.overrideWith((ref) => notifier),
        dispatchOrderApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return (
    container: ProviderScope.containerOf(
      tester.element(find.byType(DispatchCheckoutCard)),
    ),
    api: api,
  );
}

Future<void> tap(WidgetTester tester, String label) async {
  if (find.text(label).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'full UI demo goes through separate deposit, waiting and cancellation pages',
    (tester) async {
      final result = await setup(tester);
      await tap(tester, '检查并评估运单');
      expect(find.textContaining('模拟评估 ·'), findsOneWidget);
      var submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '确认运单，前往模拟支付'),
      );
      expect(submit.onPressed, isNull);
      await tap(tester, '信息真实、无违禁品');
      await tap(tester, '确认运单，前往模拟支付');
      expect(find.byType(DispatchDepositPage), findsOneWidget);
      expect(result.api.payments, 0);
      await tap(tester, '模拟支付定金');
      await tap(tester, '确认');
      expect(find.byType(DispatchWaitingPage), findsOneWidget);
      expect(find.textContaining('订单已进入派单大厅'), findsOneWidget);
      await tap(tester, '取消运单');
      await tap(tester, '确认');
      expect(find.byType(DispatchCancelledPage), findsOneWidget);
      expect(find.textContaining('定金已全额模拟退回'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing readiness and prohibited evaluation cannot create or pay',
    (tester) async {
      final result = await setup(tester, enabled: false);
      await tap(tester, '检查并评估运单');
      expect(find.text('模拟评估未启用'), findsOneWidget);
      expect(result.api.assessments, 0);
      result.api.enabled = true;
      result.api.prohibited = true;
      await tap(tester, '检查并评估运单');
      await tap(tester, '信息真实、无违禁品');
      final submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '确认运单，前往模拟支付'),
      );
      expect(submit.onPressed, isNull);
      expect(result.api.keys, isEmpty);
    },
  );
  testWidgets(
    'lost create response retains persisted attempt key across retry',
    (tester) async {
      final result = await setup(tester, loseResponse: true);
      await tap(tester, '检查并评估运单');
      await tap(tester, '信息真实、无违禁品');
      await tap(tester, '确认运单，前往模拟支付');
      expect(find.byType(DispatchDepositPage), findsNothing);
      final key = result.container
          .read(waybillDraftProvider)
          .draft
          .value('submission.requestKey');
      expect(key, isNotEmpty);
      await tap(tester, '确认运单，前往模拟支付');
      expect(result.api.keys, [key, key]);
      expect(find.byType(DispatchDepositPage), findsOneWidget);
    },
  );
  testWidgets('unconfirmed payment keeps deposit page until server confirms', (
    tester,
  ) async {
    final result = await setup(tester);
    await tap(tester, '检查并评估运单');
    await tap(tester, '信息真实、无违禁品');
    await tap(tester, '确认运单，前往模拟支付');
    result.api.failPayment = true;
    await tap(tester, '模拟支付定金');
    await tap(tester, '确认');
    expect(find.byType(DispatchDepositPage), findsOneWidget);
    expect(find.byType(DispatchWaitingPage), findsNothing);
    expect(find.text('模拟付款未确认，请刷新订单'), findsOneWidget);
  });
  testWidgets('editing a reviewed waybill resets assessment and declaration', (
    tester,
  ) async {
    final result = await setup(tester);
    await tap(tester, '检查并评估运单');
    await tap(tester, '信息真实、无违禁品');
    result.container.read(waybillDraftProvider.notifier).update('count', '3');
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, '确认运单，前往模拟支付'),
          )
          .onPressed,
      isNull,
    );
  });
}
