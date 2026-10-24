import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/widgets/dispatch_contact_actions.dart';
import 'package:uav_pilot_app/services/dispatch_navigation.dart';
import '../dispatch_order_test_support.dart';

DispatchOrder order(String stage) => DispatchOrder(
  ApiDispatchOrderVO.fromJson(
    orderJson(stage: stage, funds: 'PAID')
      ..['assignedPilotId'] = 77
      ..['assignmentVersion'] = 3
      ..['fields'] = {'start.lat': '28.2', 'start.lng': '113.0'},
  ),
);
void main() {
  testWidgets('unassigned and cancelled orders have no contact actions', (
    tester,
  ) async {
    for (final stage in [
      'WAITING_ACCEPTANCE',
      'CANCELLED',
      'AWAITING_DEPOSIT',
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: DispatchContactActions(order: order(stage))),
          ),
        ),
      );
      expect(find.text('订单聊天'), findsNothing);
      expect(find.text('导航到起点'), findsNothing);
    }
  });
  testWidgets(
    'pilot contact opens current assignment chat and ground navigation returns explicit errors',
    (tester) async {
      var launches = 0;
      final item = order('PILOT_PREPARING');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: DispatchContactActions(order: item, pilot: true),
            ),
          ),
          GoRoute(
            path: '/pilot/dispatch/orders/:id/chat',
            builder: (_, state) => Scaffold(
              body: Text('版本${state.uri.queryParameters['version']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dispatchNavigationProvider.overrideWithValue(
              DispatchNavigation(
                launch: (_) async {
                  launches++;
                  return false;
                },
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.tap(find.text('导航到起点'));
      await tester.pumpAndSettle();
      expect(launches, 1);
      expect(find.textContaining('无法打开高德导航'), findsOneWidget);
      await tester.tap(find.text('订单聊天'));
      await tester.pumpAndSettle();
      expect(find.text('版本3'), findsOneWidget);
    },
  );
  testWidgets(
    'shipper sees chat only; completed order shows history and no navigation',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DispatchContactActions(order: order('PILOT_PREPARING')),
            ),
          ),
        ),
      );
      expect(find.text('订单聊天'), findsOneWidget);
      expect(find.text('导航到起点'), findsNothing);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DispatchContactActions(
                order: order('COMPLETED'),
                pilot: true,
              ),
            ),
          ),
        ),
      );
      expect(find.text('查看订单聊天'), findsOneWidget);
      expect(find.text('导航到起点'), findsNothing);
    },
  );
}
