import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/trade_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/routes/app_router.dart';
import 'package:uav_pilot_app/pages/orders/trade_list_page.dart';
import '../routes/user_shell_route_test.dart' show pumpLoggedInApp;
import '../test_support.dart';

const counts = {
  'totalOrderCount': 250,
  'completedTradeCount': 130,
  'publishedTaskCount': 12,
  'boughtOrderCount': 240,
  'soldOrderCount': 10,
  'pendingReviewCount': 3,
};

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });
  test('Missing or invalid counts cannot silently become zero', () {
    expect(() => TradeStats.fromJson({}), throwsFormatException);
    expect(
      () => TradeStats.fromJson({...counts, 'soldOrderCount': -1}),
      throwsFormatException,
    );
    expect(
      TradeStats.fromJson({...counts, 'soldOrderCount': 0}).soldOrderCount,
      0,
    );
  });

  testWidgets(
    'Real stats, four separate entry endpoints and server pagination',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final requests = <String>[];
      var statsCalls = 0;
      final container = await pumpLoggedInApp(
        tester,
        handler: (options) async {
          requests.add(options.uri.toString());
          if (options.uri.path == '/order/stats') {
            statsCalls++;
            return jsonResponse(200, {'success': true, 'data': counts});
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
          if ([
            '/order/list',
            '/order/sold',
            '/order/pending-review',
          ].contains(options.uri.path)) {
            final page = int.parse(options.uri.queryParameters['page']!);
            return jsonResponse(200, {
              'success': true,
              'data': {
                'orders': [
                  {
                    'orderNum': 'ORDER-$page',
                    'taskName': '测试吊运',
                    'totalAmount': 300,
                    'orderStatus': 4,
                  },
                ],
                'currentPage': page,
                'totalPages': 2,
                'totalElements': 21,
              },
            });
          }
          return jsonResponse(200, {'success': false, 'message': 'stub'});
        },
      );
      final router = container.read(goRouterProvider);
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('已完成 130 笔 · 累计 250 单'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('切换夜晚模式'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final kind in ['published', 'sold', 'bought', 'review']) {
        await tester.tap(find.byKey(ValueKey('trade-$kind')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TradeListPage>(find.byType(TradeListPage)).kind,
          kind,
        );
        if (kind != 'published') {
          expect(find.text('ORDER-0\n已完成'), findsOneWidget);
          await tester.tap(find.text('下一页'));
          await tester.pumpAndSettle();
          expect(find.text('ORDER-1\n已完成'), findsOneWidget);
        } else {
          expect(find.text('暂无我发布的记录'), findsOneWidget);
        }
        router.pop();
        await tester.pumpAndSettle();
      }
      expect(
        requests.any((path) => path.contains('/order/sold?page=1')),
        isTrue,
      );
      expect(
        requests.any((path) => path.contains('/order/pending-review?page=1')),
        isTrue,
      );
      expect(statsCalls, greaterThan(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Stats failure shows retry and keeps entries available', (
    tester,
  ) async {
    var fail = true;
    final container = await pumpLoggedInApp(
      tester,
      handler: (options) async {
        if (options.uri.path == '/order/stats') {
          return jsonResponse(
            200,
            fail
                ? {'success': false, 'message': 'failed'}
                : {'success': true, 'data': counts},
          );
        }
        return jsonResponse(200, {'success': false, 'message': 'stub'});
      },
    );
    container.read(goRouterProvider).go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('统计暂未加载'), findsOneWidget);
    expect(find.byKey(const ValueKey('trade-review')), findsOneWidget);
    fail = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('已完成 130 笔 · 累计 250 单'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
