import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_map_home.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import 'package:uav_pilot_app/widgets/mission_map.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/models/dispatch_tracking.dart';
import '../models/dispatch_tracking_test.dart' show trackingOrder;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => binding.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true),
  );
  tearDown(binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
  testWidgets(
    'map pin opens draggable order timeline; same start exposes every order and details route',
    (tester) async {
      final orders = [
        trackingOrder('a'),
        trackingOrder('b'),
        trackingOrder('c', fields: {'start.lat': '28.2', 'start.lng': '113.1'}),
      ];
      late StateSetter rebuild;
      List<DispatchOrder> current = orders;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return DispatchMapHome(orders: current);
                },
              ),
            ),
          ),
          GoRoute(
            path: '/dispatch/orders/:id',
            builder: (_, state) =>
                Scaffold(body: Text('详情 ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            amapMapConfigProvider.overrideWith(
              (ref) async => throw StateError('offline'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      final map = tester.widget<MissionMap>(find.byType(MissionMap));
      expect(map.orderMarkers, hasLength(2));
      map.onOrderMarkerTap!(dispatchMapStops(orders).first.id);
      await tester.pumpAndSettle();
      expect(find.text('该起点 · 2 单'), findsOneWidget);
      expect(find.byKey(const ValueKey('map-order-c')), findsNothing);
      await tester.tap(find.text('吊运任务').first);
      await tester.pumpAndSettle();
      expect(find.text('订单跟踪'), findsOneWidget);
      expect(find.text('等待飞手接单'), findsOneWidget);
      current = [
        trackingOrder('a', stage: 'PILOT_PREPARING'),
        orders[1],
        orders[2],
      ];
      rebuild(() {});
      await tester.pumpAndSettle();
      expect(find.text('飞手已接单，准备中'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('查看进度').first,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('查看进度').first);
      await tester.pumpAndSettle();
      expect(find.text('详情 a'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map failure and missing coordinates preserve the order drawer and empty creation entry',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            amapMapConfigProvider.overrideWith(
              (ref) async => throw StateError('offline'),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DispatchMapHome(
                orders: [trackingOrder('no-position', fields: {})],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('地图服务暂不可用'), findsOneWidget);
      expect(find.text('1 单暂无地图位置'), findsOneWidget);
      expect(
        tester.widget<MissionMap>(find.byType(MissionMap)).orderMarkers,
        isEmpty,
      );
      expect(find.text('查看进度'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('dispatch-home-drawer')),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
