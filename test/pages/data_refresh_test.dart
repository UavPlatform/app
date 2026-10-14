import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/pages/orders/order_list_page.dart';
import 'package:uav_pilot_app/pages/orders/trade_list_page.dart';
import 'package:uav_pilot_app/pages/messages/system_messages_view.dart';
import 'package:uav_pilot_app/pages/pay/pay_page.dart';
import '../test_support.dart';
import 'docs_alignment_test.dart' show overrides;

void main() {
  for (final failed in [false, true]) {
    for (final entry in <String, Widget>{
      '/order/list': const OrderListPage(),
      '/order/sold': const TradeListPage(kind: 'sold'),
      '/chat/Message/messages/99': const SystemMessagesView(sessionId: 99),
      '/order/detail': const PayPage(orderNum: 'O-1'),
    }.entries) {
      testWidgets(
        '${entry.key}: pull refresh ${failed ? 'error' : 'short or empty content'} actually reloads',
        (tester) async {
          var requests = 0;
          final adapter = StubAdapter((options) async {
            final path = options.uri.path;
            if (path == entry.key) {
              requests++;
              if (failed) {
                return jsonResponse(200, {'success': false, 'message': '加载失败'});
              }
              return jsonResponse(200, {
                'success': true,
                'data': switch (path) {
                  '/order/detail' => {
                    'orderNum': 'O-1',
                    'orderStatus': 0,
                    'totalAmount': 10,
                  },
                  '/chat/Message/messages/99' => [],
                  _ => {
                    'orders': [],
                    'currentPage': 0,
                    'totalPages': 0,
                    'totalElements': 0,
                  },
                },
              });
            }
            if (path == '/chat/session/list') {
              return jsonResponse(200, {'success': true, 'data': []});
            }
            if (path == '/task/list') {
              return jsonResponse(200, {
                'success': true,
                'data': {'tasks': []},
              });
            }
            return jsonResponse(200, {'success': true});
          });
          await tester.pumpWidget(
            ProviderScope(
              overrides: await overrides(adapter),
              child: MaterialApp(home: entry.value),
            ),
          );
          await tester.pumpAndSettle();
          expect(requests, 1);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 350),
          );
          await tester.pumpAndSettle();
          expect(requests, 2);
        },
      );
    }
  }
}
