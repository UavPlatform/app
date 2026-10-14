// 订单评价（/review/*）：已完成订单在详情页评价飞手、评价后只读回显；「我的评价」列表与空态。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/orders/order_detail_page.dart';
import 'package:uav_pilot_app/pages/profile/my_reviews_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

const taskNum = 'T-DONE';

Map<String, dynamic> completedTask({String orderStatus = 'COMPLETED'}) => {
      'id': 1,
      'taskNum': taskNum,
      'taskName': '林场水泥吊运',
      'userId': 7,
      'taskType': 'TRANSPORT',
      'taskStatus': 'COMPLETED',
      'matchStatus': orderStatus == 'COMPLETED' ? 'CLOSED' : 'PENDING_ACCEPTANCE',
      'orderNum': 'ORD-DONE',
      'orderStatus': orderStatus,
      'totalAmount': 388.44,
      'riderId': 8,
      'riderName': 'pilot_liming',
    };

Future<List<Override>> overrides(StubAdapter adapter) async {
  SharedPreferences.setMockInitialValues({
    'jwt_token': makeJwt(userId: 7),
    'server_url': 'http://stub.local:8081',
  });
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    httpClientProvider.overrideWithValue(HttpClient(TokenStorage(prefs), adapter: adapter)),
  ];
}

void main() {
  testWidgets('已完成订单：评价飞手 → 提交 rating/content → 只读回显', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Map<String, dynamic>? submitted;
    final adapter = StubAdapter((options) async {
      final path = options.uri.path;
      if (path == '/task/detail') {
        return jsonResponse(200, {'success': true, 'code': 200, 'data': completedTask()});
      }
      if (path == '/review/ORD-DONE') {
        if (submitted == null) {
          return jsonResponse(404, {'success': false, 'message': '评价不存在'});
        }
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'orderNum': 'ORD-DONE',
            'rating': int.parse('${submitted!['rating']}'),
            'content': submitted!['content'],
            'createTime': '2026-10-11T02:10:00',
          },
        });
      }
      if (path == '/review/submit') {
        submitted = Map<String, dynamic>.from(options.uri.queryParameters);
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {'orderNum': 'ORD-DONE', 'rating': 4},
        });
      }
      return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
    });

    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(adapter),
      child: const MaterialApp(home: OrderDetailPage(taskNum: taskNum)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('服务评价'), findsOneWidget);
    expect(find.text('订单已完成，给pilot_liming的服务打个分吧'), findsOneWidget);

    await tester.tap(find.text('评价飞手'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('review-star-4')));
    await tester.pump();
    expect(find.text('满意'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('review-content-field')), '准时，绑扎很稳');
    await tester.tap(find.text('提交评价'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!['orderNum'], 'ORD-DONE');
    expect(submitted!['rating'], '4');
    expect(submitted!['content'], '准时，绑扎很稳');
    expect(find.text('评价飞手'), findsNothing, reason: '一单一评：提交后不再提供入口');
    expect(find.text('4 分'), findsOneWidget);
    expect(find.text('准时，绑扎很稳'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('待验收（未确认完成）：不展示评价区块', (tester) async {
    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/task/detail') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': completedTask(orderStatus: 'WAITING_CONFIRM'),
        });
      }
      return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
    });
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(adapter),
      child: const MaterialApp(home: OrderDetailPage(taskNum: taskNum)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('服务评价'), findsNothing);
  });

  testWidgets('我的评价：列表展示星级/内容/订单号；空态有引导文案', (tester) async {
    var empty = false;
    final adapter = StubAdapter((options) async {
      if (options.uri.path == '/review/my') {
        return jsonResponse(200, {
          'success': true,
          'code': 200,
          'data': {
            'reviews': empty
                ? []
                : [
                    {
                      'orderNum': 'ORD-DONE',
                      'rating': 5,
                      'content': '准时专业',
                      'createTime': '2026-10-11T01:30:00',
                    },
                  ],
            'currentPage': 0,
            'totalPages': 1,
            'totalElements': empty ? 0 : 1,
          },
        });
      }
      return jsonResponse(200, {'success': false});
    });
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(adapter),
      child: const MaterialApp(home: MyReviewsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('准时专业'), findsOneWidget);
    expect(find.text('5 分'), findsOneWidget);
    expect(find.text('订单号 ORD-DONE'), findsOneWidget);
    expect(find.text('2026-10-11 01:30'), findsOneWidget);

    empty = true;
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('还没有评价过订单'), findsOneWidget);
  });
}
