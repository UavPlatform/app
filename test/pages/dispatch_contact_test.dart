import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/pages/chat/dispatch_chat_page.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';
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
  testWidgets(
    'completed order chat directs to the latest order instead of retrying',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const DispatchChatPage(orderId: 'demo-order', version: 3),
          ),
          GoRoute(
            path: '/dispatch/orders/:id',
            builder: (_, state) =>
                Scaffold(body: Text('订单 ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dispatchOrderProvider(
              'demo-order',
            ).overrideWith((ref) async => order('COMPLETED')),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('本次订单会话已结束'), findsOneWidget);
      expect(find.text('重试'), findsNothing);
      await tester.tap(find.text('查看最新订单'));
      await tester.pumpAndSettle();
      expect(find.text('订单 demo-order'), findsOneWidget);
    },
  );

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
