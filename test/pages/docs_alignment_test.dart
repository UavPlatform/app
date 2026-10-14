// REQ-APP-001 / REQ-APP-002 / ADR-0003: server authority and customer workflow.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/order_api.dart';
import 'package:uav_pilot_app/models/task_vo.dart';
import 'package:uav_pilot_app/pages/orders/order_list_page.dart';
import 'package:uav_pilot_app/pages/orders/pay_entry.dart';
import 'package:uav_pilot_app/pages/pay/pay_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/routes/app_router.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';
import '../routes/user_shell_route_test.dart' show pumpLoggedInApp;

TaskVo task({
  String phase = 'NEGOTIATING',
  String status = 'IDLE',
  String? order,
}) => TaskVo.fromJson({
  'id': 1,
  'taskNum': 'T-1',
  'taskName': '吊运需求',
  'userId': 7,
  'taskType': 'TRANSPORT',
  'taskStatus': status,
  'matchStatus': phase,
  'orderStatus': order,
});

Future<List<Override>> overrides(StubAdapter adapter) async {
  SharedPreferences.setMockInitialValues({
    'jwt_token': makeJwt(userId: 7),
    'server_url': 'http://stub.local:8081',
  });
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    httpClientProvider.overrideWithValue(
      HttpClient(TokenStorage(prefs), adapter: adapter),
    ),
  ];
}

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });
  test(
    'Delivered is not accepted, confirmed is not necessarily airborne, paid demands cannot be deleted',
    () {
      expect(
        task(
          phase: 'PENDING_ACCEPTANCE',
          status: 'COMPLETED',
          order: 'WAITING_CONFIRM',
        ).userStageLabel,
        '待验收',
      );
      expect(task(phase: 'CONFIRMED', order: 'PAID').userStageLabel, '可以开始作业');
      expect(
        task(
          phase: 'CONFIRMED',
          status: 'IN_PROGRESS',
          order: 'PAID',
        ).userStageLabel,
        '进行中',
      );
      expect(
        task(
          phase: 'AWAITING_RIDER_CONFIRM',
          order: 'PAID',
        ).canDeleteUserDemand,
        isFalse,
      );
      expect(task(order: 'MATCHING').canDeleteUserDemand, isTrue);
      expect(
        task(
          phase: 'CLOSED',
          status: 'COMPLETED',
          order: 'COMPLETED',
        ).userStageLabel,
        '已完成',
      );
    },
  );
  test('A sub-cent price difference still violates the locked quote', () {
    expect(payAmountMatches(totalAmount: 980.001, quotedAmount: 980), isFalse);
    expect(payAmountMatches(totalAmount: 980, quotedAmount: 980), isTrue);
    expect(OrderStatusCode.labelOf(6), '争议中');
    expect(OrderStatusCode.labelOf(7), '待撮合');
    expect(
      const OrderVo(orderNum: 'O', orderStatus: 7, totalAmount: 0).priceLabel,
      '待飞手报价',
    );
  });

  testWidgets(
    'Prepay success is not payment success; query server state without paying again',
    (tester) async {
      var paid = false;
      var posts = 0;
      final adapter = StubAdapter((options) async {
        if (options.uri.path == '/pay/O-1') {
          posts++;
          expect(options.uri.queryParameters.containsKey('openid'), isFalse);
          return jsonResponse(200, {
            'success': true,
            'data': {'orderNum': 'O-1', 'prepayId': 'real-prepay'},
          });
        }
        return jsonResponse(200, {
          'success': true,
          'data': {
            'orderNum': 'O-1',
            'totalAmount': 980,
            'orderStatus': paid ? 1 : 0,
          },
        });
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: await overrides(adapter),
          child: const MaterialApp(
            home: PayPage(orderNum: 'O-1', quotedAmount: 980),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认支付 ¥980.00'));
      await tester.pumpAndSettle();
      expect(find.text('支付成功'), findsNothing);
      expect(find.text('查询支付结果'), findsOneWidget);
      paid = true;
      await tester.tap(find.text('查询支付结果'));
      await tester.pumpAndSettle();
      expect(find.text('支付成功'), findsOneWidget);
      expect(posts, 1);
      expect(find.textContaining('支付流水号'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Changing a locked amount at checkout blocks the payment endpoint',
    (tester) async {
      final adapter = StubAdapter((options) async {
        expect(options.uri.path, '/order/detail');
        return jsonResponse(200, {
          'success': true,
          'data': {'orderNum': 'O-1', 'totalAmount': 981, 'orderStatus': 0},
        });
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: await overrides(adapter),
          child: const MaterialApp(
            home: PayPage(orderNum: 'O-1', quotedAmount: 980),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('订单金额与选定飞手的系统报价不一致，已阻止支付'), findsOneWidget);
      expect(find.textContaining('确认支付'), findsNothing);
    },
  );

  testWidgets(
    'Orders use backend filtering and pagination, not filtering just the first 20',
    (tester) async {
      final queries = <Map<String, String>>[];
      final adapter = StubAdapter((options) async {
        if (options.uri.path == '/order/list') {
          final query = options.uri.queryParameters;
          queries.add(query);
          final page = int.parse(query['page']!);
          return jsonResponse(200, {
            'success': true,
            'data': {
              'orders': [
                {
                  'orderNum': 'O-$page',
                  'orderStatus': int.parse(query['status'] ?? '7'),
                  'totalAmount': 0,
                },
              ],
              'currentPage': page,
              'totalPages': 2,
              'totalElements': 21,
            },
          });
        }
        if (options.uri.path == '/task/list') {
          return jsonResponse(200, {
            'success': true,
            'data': {
              'tasks': [],
              'currentPage': 0,
              'totalPages': 0,
              'totalElements': 0,
            },
          });
        }
        return jsonResponse(200, {'success': true, 'data': []});
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: await overrides(adapter),
          child: const MaterialApp(home: OrderListPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('待飞手报价'), findsOneWidget);
      expect(find.text('¥0.00'), findsNothing);
      await tester.tap(find.text('待支付'));
      await tester.pumpAndSettle();
      expect(queries.last['status'], '0');
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      expect(queries.last['page'], '1');
      expect(queries.last['status'], '0');
      expect(find.text('订单号 O-1'), findsOneWidget);
    },
  );

  testWidgets('Ordinary users cannot navigate into the pilot shell', (
    tester,
  ) async {
    final container = await pumpLoggedInApp(tester);
    final router = container.read(goRouterProvider);
    router.go('/pilot/tasks');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(tester.takeException(), isNull);
  });
}
