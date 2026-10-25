import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uav_pilot_app/services/dispatch_realtime.dart';
import 'package:uav_pilot_app/providers/dispatch_realtime_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/pages/pilot/dispatch_pilot_pages.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_order_pages.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../dispatch_matching_test_support.dart';

class _Events implements DispatchEventSource {
  _Events(this.events);
  final StreamController<String> events;
  @override
  Stream<String> connect(CancelToken cancel) => events.stream;
}

Future<void> tap(WidgetTester tester, String label) async {
  final found = find.text(label);
  if (found.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      found,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final target = found.last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<FakeMatchingApi> setupMatching(
  WidgetTester tester, {
  bool shipper = false,
  StreamController<String>? events,
}) async {
  SharedPreferences.setMockInitialValues({});
  final client = HttpClient(
    TokenStorage(await SharedPreferences.getInstance()),
  );
  addTearDown(() => client.dio.close());
  final api = FakeMatchingApi(client);
  final router = GoRouter(
    initialLocation: shipper ? '/shipper' : '/hall',
    routes: [
      GoRoute(path: '/hall', builder: (_, _) => const DispatchPilotHallPage()),
      GoRoute(
        path: '/pilot/jobs',
        builder: (_, _) => const DispatchPilotJobsPage(),
      ),
      GoRoute(
        path: '/pilot/dispatch/orders/:id',
        builder: (_, state) =>
            DispatchPilotOrderPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shipper',
        builder: (_, _) => const DispatchOrderPage(orderId: 'demo-order'),
      ),
      GoRoute(
        path: '/dispatch/orders',
        builder: (_, _) => const DispatchOrderListPage(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dispatchOrderApiProvider.overrideWithValue(api),
        if (events != null) ...[
          dispatchEventSourceProvider.overrideWithValue(_Events(events)),
        ],
        waybillDraftScopeProvider.overrideWithValue('matching-user'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets(
    'pilot hall claims then shows separate preparation and arrival pages and releases',
    (tester) async {
      final api = await setupMatching(tester);
      expect(find.textContaining('13800000000'), findsNothing);
      await tap(tester, '立即接单');
      expect(find.byType(DispatchPilotPreparationPage), findsOneWidget);
      for (
        var i = 0;
        i < 15 && find.textContaining('联系人：').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('13800000000'), findsWidgets);
      await tap(tester, '我已到场');
      await tap(tester, '确认');
      expect(find.byType(DispatchPilotArrivalPage), findsOneWidget);
      await tap(tester, '取消接单，重新派单');
      await tap(tester, '确认');
      expect(find.byType(DispatchPilotJobsPage), findsOneWidget);
      expect(find.text('暂无当前指派订单'), findsOneWidget);
      expect(api.order!.waiting, isTrue);
    },
  );
  testWidgets('lost claim prevents optimistic preparation navigation', (
    tester,
  ) async {
    final api = await setupMatching(tester);
    api.failClaim = true;
    await tap(tester, '立即接单');
    expect(find.byType(DispatchPilotPreparationPage), findsNothing);
    expect(find.textContaining('订单已被接走'), findsOneWidget);
    expect(api.claims, 1);
  });
  testWidgets('double tap while claim is pending issues one command', (
    tester,
  ) async {
    final api = await setupMatching(tester);
    api.claimGate = Completer<void>();
    await tester.tap(find.text('立即接单'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '立即接单'))
          .onPressed,
      isNull,
    );
    expect(api.claims, 1);
    api.claimGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DispatchPilotPreparationPage), findsOneWidget);
  });
  testWidgets(
    'shipper automatically sees claim arrival and redispatch from SSE',
    (tester) async {
      final events = StreamController<String>.broadcast();
      addTearDown(() {
        unawaited(events.close());
      });
      final api = await setupMatching(tester, shipper: true, events: events);
      expect(find.byType(DispatchWaitingPage), findsOneWidget);
      api.setStage('PILOT_PREPARING');
      events.add('change');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(DispatchPreparingPage), findsOneWidget);
      api.setStage('PILOT_ARRIVED');
      events.add('change');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(DispatchArrivedPage), findsOneWidget);
      api.setStage('WAITING_ACCEPTANCE');
      events.add('change');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(DispatchWaitingPage), findsOneWidget);
    },
  );
  testWidgets(
    'slow status requests coalesce SSE events until response completes',
    (tester) async {
      final events = StreamController<String>.broadcast();
      addTearDown(() {
        unawaited(events.close());
      });
      final api = await setupMatching(tester, shipper: true, events: events);
      api.readGate = Completer<DispatchOrder>();
      events.add('change');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      final reads = api.reads;
      for (var i = 0; i < 3; i++) {
        events.add('change');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(api.reads, reads);
      api.readGate!.complete(api.order!);
      await tester.pumpAndSettle();
    },
  );
}
