import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/pages/messages/dispatch_notification_page.dart';
import 'package:uav_pilot_app/providers/dispatch_notification_provider.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import 'package:uav_pilot_app/widgets/dispatch_notification_entry.dart';
import '../dispatch_notification_test_support.dart';

class _DelayedNotifications extends FakeNotificationApi {
  _DelayedNotifications(super.client);
  final pending = <Completer<ApiDispatchNotificationPageVO>>[];
  @override
  Future<ApiDispatchNotificationPageVO> list(int page) {
    final request = Completer<ApiDispatchNotificationPageVO>();
    pending.add(request);
    return request.future;
  }
}

void main() {
  test(
    'late response from previous account cannot populate current inbox',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
      );
      final api = _DelayedNotifications(client);
      final scope = StateProvider((ref) => 'account-a');
      final container = ProviderContainer(
        overrides: [
          waybillDraftScopeProvider.overrideWith((ref) => ref.watch(scope)),
          dispatchNotificationApiProvider.overrideWithValue(api),
        ],
      );
      final subscription = container.listen(dispatchInboxProvider, (_, _) {});
      addTearDown(() {
        subscription.close();
        container.dispose();
        client.dio.close();
      });
      expect(api.pending.length, 1);
      container.read(scope.notifier).state = 'account-b';
      await Future<void>.delayed(Duration.zero);
      expect(api.pending.length, 2);
      api.pending[0].complete(
        ApiDispatchNotificationPageVO(
          items: [notice('private-a')],
          page: 0,
          hasNext: false,
          unreadCount: 1,
        ),
      );
      api.pending[1].complete(
        ApiDispatchNotificationPageVO(
          items: [notice('private-b')],
          page: 0,
          hasNext: false,
          unreadCount: 1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(dispatchInboxProvider).items.single.notificationId,
        'private-b',
      );
    },
  );
  testWidgets(
    'two entry points share unread count and old notification opens current order route',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
      );
      final api = FakeNotificationApi(client);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: Column(
                children: [
                  DispatchNotificationEntry(),
                  DispatchNotificationEntry(menu: true),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const DispatchNotificationPage(),
          ),
          GoRoute(
            path: '/dispatch/orders/:id',
            builder: (_, state) =>
                Scaffold(body: Text('当前阶段：运输中 ${state.pathParameters['id']}')),
          ),
        ],
      );
      addTearDown(() {
        router.dispose();
        client.dio.close();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWithValue('user1'),
            dispatchNotificationApiProvider.overrideWithValue(api),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7'), findsNWidgets(2));
      await tester.tap(find.text('消息通知'));
      await tester.pumpAndSettle();
      expect(api.reads, isEmpty); // Listing the inbox is read-only.
      expect(find.text('订单 order1'), findsOneWidget);
      await tester.tap(find.text('未读 · 飞手已到场'));
      await tester.pumpAndSettle();
      expect(api.reads, ['n1']);
      expect(find.text('当前阶段：运输中 order1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'paging deduplicates notifications and read failure preserves unread state',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
      );
      final api = FakeNotificationApi(client);
      final inbox = DispatchInboxNotifier(api);
      addTearDown(() {
        inbox.dispose();
        client.dio.close();
      });
      await inbox.load();
      api.items = [notice('n1'), notice('n2', order: 'order2')];
      await inbox.load();
      expect(inbox.state.items.map((item) => item.notificationId), [
        'n1',
        'n2',
      ]);
      api.failure = StateError('未确认已读');
      await expectLater(inbox.read('n1'), throwsStateError);
      expect(inbox.state.isRead(inbox.state.items.first), isFalse);
      api.failure = null;
      await inbox.read('n1');
      expect(inbox.state.isRead(inbox.state.items.first), isTrue);
      expect(inbox.state.isRead(inbox.state.items.last), isFalse);
    },
  );
}
