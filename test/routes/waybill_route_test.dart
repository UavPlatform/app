import 'package:go_router/go_router.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import '../test_support.dart';
import '../dispatch_order_test_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/waybill/waybill_page.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_order_pages.dart';
import 'package:uav_pilot_app/pages/pilot/equipment_borrow_page.dart';
import 'package:uav_pilot_app/routes/app_router.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import '../models/waybill_draft_test.dart' show validCargo, validSite;

import 'user_shell_route_test.dart' show pumpLoggedInApp;

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });

  testWidgets(
    'blocked checkout returns to order home without stacking its shell',
    (tester) async {
      const blocker = '真实空域服务尚未接入，且模拟评估未启用；暂不能下单';
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = await pumpLoggedInApp(
        tester,
        handler: (options) async => jsonResponse(200, {
          'success': true,
          'data': switch (options.uri.path) {
            '/dispatch/orders' => [],
            '/dispatch/config' => {
              'currency': 'CNY',
              'depositAmount': 100,
              'pilotServiceFee': 100,
              'orderingEnabled': false,
            },
            '/dispatch/readiness' => {
              'orderingEnabled': false,
              'paymentMode': 'SIMULATED',
              'blockers': [blocker],
            },
            _ => 0,
          },
        }),
      );
      final router = container.read(goRouterProvider);
      container
          .read(waybillDraftProvider.notifier)
          .restore(
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
      router.push('/waybill/new');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('检查并评估运单'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('检查并评估运单'));
      await tester.pumpAndSettle();
      expect(find.text(blocker), findsOneWidget);
      await tester.tap(find.byTooltip('更多订单操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('查看我的派单运单'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.byType(DispatchOrderListPage), findsOneWidget);
      expect(router.canPop(), isFalse);

      // Returning to the form and using system back must still work.
      router.push('/waybill/new');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'order home keeps navigation and empty state creates an isolated form',
    (tester) async {
      final container = await pumpLoggedInApp(
        tester,
        handler: (options) async => jsonResponse(200, {
          'success': true,
          'data': options.uri.path == '/dispatch/orders' ? [] : 0,
        }),
      );
      expect(find.byType(DispatchOrderListPage), findsOneWidget);
      expect(find.byType(WaybillPage), findsNothing);
      final nav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(nav.items.map((item) => item.label), ['首页', '创建订单', '我的']);
      expect(nav.currentIndex, 0);
      await tester.tap(find.text('创建第一单'));
      await tester.pumpAndSettle();
      expect(find.byType(WaybillPage), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      await tester.tap(find.byKey(const ValueKey('edit-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '普通'));
      await tester.tap(find.byKey(const ValueKey('waybill-editor-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(goRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/home',
      );
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      await tester.tap(find.text('创建订单'));
      await tester.pumpAndSettle();
      expect(find.byType(WaybillPage), findsOneWidget);
      expect(
        container.read(waybillDraftProvider).draft.value('category'),
        '普通',
      );
      expect(find.text('普通'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(goRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/profile',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('old order list links return to canonical home', (tester) async {
    final container = await pumpLoggedInApp(tester);
    expect(find.text('创建第一单'), findsNothing);
    for (final path in ['/orders', '/dispatch/orders']) {
      container.read(goRouterProvider).go(path);
      await tester.pumpAndSettle();
      expect(
        container
            .read(goRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/home',
      );
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    }
    expect(find.text('旧版订单'), findsNothing);
  });

  testWidgets('populated home opens the current order stage', (tester) async {
    final data = orderJson(stage: 'WAITING_ACCEPTANCE', funds: 'PAID');
    await pumpLoggedInApp(
      tester,
      handler: (options) async {
        if (options.uri.path == '/dispatch/orders') {
          return jsonResponse(200, {
            'success': true,
            'data': [data],
          });
        }
        if (options.uri.path == '/dispatch/orders/demo-order') {
          return jsonResponse(200, {'success': true, 'data': data});
        }
        return jsonResponse(200, {'success': false, 'message': 'stub'});
      },
    );
    expect(find.text('创建第一单'), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('dispatch-home-drawer')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看进度'));
    await tester.pumpAndSettle();
    expect(find.byType(DispatchWaitingPage), findsOneWidget);
    expect(
      GoRouterState.of(
        tester.element(find.byType(DispatchWaitingPage)),
      ).uri.path,
      '/dispatch/orders/demo-order',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pilot account cannot enter shipper waybill route', (
    tester,
  ) async {
    final container = await pumpLoggedInApp(tester, role: 1);
    container.read(goRouterProvider).go('/waybill/new');
    await tester.pumpAndSettle();
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/pilot/home',
    );
    expect(find.byType(WaybillPage), findsNothing);
    container.read(goRouterProvider).go('/dispatch/orders/example');
    await tester.pumpAndSettle();
    expect(
      container.read(goRouterProvider).routeInformationProvider.value.uri.path,
      '/pilot/home',
    );
    container.read(goRouterProvider).go('/pilot/equipment');
    await tester.pumpAndSettle();
    expect(find.byType(EquipmentBorrowPage), findsOneWidget);
  });
  for (final size in [const Size(360, 740), const Size(390, 844)]) {
    testWidgets('HUD first order is fully visible above navigation on $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = orderJson(stage: 'IN_TRANSIT', funds: 'PAID')
        ..['assignedPilotId'] = 77
        ..['assignmentVersion'] = 1
        ..['fields'] = {
          'category': '普通',
          'start.site': '空地',
          'end.site': '哈哈哈',
          'start.lat': '27.9',
          'start.lng': '112.9',
        };
      await pumpLoggedInApp(
        tester,
        handler: (options) async => jsonResponse(200, {
          'success': true,
          'data': options.uri.path == '/dispatch/orders' ? [data] : 0,
        }),
      );
      expect(find.text('上拉查看订单 · 点击卡片展开跟踪'), findsNothing);
      final card = tester.getRect(
        find.byKey(const ValueKey('map-order-demo-order')),
      );
      final nav = tester.getRect(find.byType(BottomNavigationBar));
      expect(card.bottom, lessThanOrEqualTo(nav.top - 6));
      expect(find.text('空地'), findsOneWidget);
      expect(find.text('哈哈哈'), findsOneWidget);
      expect(tester.getRect(find.text('查看进度')).bottom, lessThan(nav.top));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
