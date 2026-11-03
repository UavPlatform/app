import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import 'package:uav_pilot_app/pages/profile/order_history_page.dart';
import 'package:uav_pilot_app/providers/dispatch_order_provider.dart';

import '../../dispatch_order_test_support.dart';

void main() {
  testWidgets('history shows ended orders and opens their real details', (
    tester,
  ) async {
    DispatchOrder order(String id, String stage) => DispatchOrder(
      ApiDispatchOrderVO.fromJson({
        ...orderJson(stage: stage, funds: 'PAID'),
        'orderId': id,
        if (stage == 'COMPLETED') ...{
          'assignedPilotId': 9,
          'assignmentVersion': 1,
        },
      }),
    );
    final orders = [
      order('completed-order', 'COMPLETED'),
      order('cancelled-order', 'CANCELLED'),
      order('active-order', 'WAITING_ACCEPTANCE'),
    ];
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(path: '/history', builder: (_, _) => const OrderHistoryPage()),
        GoRoute(
          path: '/dispatch/orders/:id',
          builder: (_, state) =>
              Scaffold(body: Text(state.pathParameters['id']!)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dispatchOrdersProvider.overrideWith((ref) async => orders)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('已结单'), findsOneWidget);
    expect(find.text('已取消'), findsOneWidget);
    expect(find.text('等待接单'), findsNothing);
    await tester.tap(find.text('已结单'));
    await tester.pumpAndSettle();
    expect(find.text('completed-order'), findsOneWidget);
  });
}
