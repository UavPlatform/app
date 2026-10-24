import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/providers/dispatch_notification_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../dispatch_notification_test_support.dart';

class _PagedApi extends FakeNotificationApi {
  _PagedApi(super.client);
  final requested = <int>[];
  int? failPage;
  @override
  Future<ApiDispatchNotificationPageVO> list(int page) async {
    requested.add(page);
    if (page == failPage) throw StateError('offline');
    final start = min(page * 20, items.length);
    return ApiDispatchNotificationPageVO(
      items: items.sublist(start, min(start + 20, items.length)),
      page: page,
      hasNext: start + 20 < items.length,
      unreadCount: items.length,
    );
  }
}

void main() {
  late HttpClient client;
  late _PagedApi api;
  late DispatchInboxNotifier inbox;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    client = HttpClient(TokenStorage(await SharedPreferences.getInstance()));
    api = _PagedApi(client);
    inbox = DispatchInboxNotifier(api);
  });
  tearDown(() {
    inbox.dispose();
    client.dio.close();
  });

  test(
    'reconnect catches up multiple new pages and rebases older pagination',
    () async {
      api.items = List.generate(80, (i) => notice('old-$i'));
      await inbox.load();
      await inbox.load();
      await inbox.load();
      api.items = [...List.generate(45, (i) => notice('new-$i')), ...api.items];
      await inbox.refreshHead();
      expect(
        inbox.state.items.map((n) => n.notificationId),
        api.items.take(105).map((n) => n.notificationId),
      );
      expect(inbox.state.page, 2);
      while (inbox.state.hasNext) {
        await inbox.load();
      }
      expect(
        inbox.state.items.map((n) => n.notificationId),
        api.items.map((n) => n.notificationId),
      );
    },
  );

  test(
    'previously exhausted inbox remains pageable after new arrivals',
    () async {
      api.items = List.generate(25, (i) => notice('old-$i'));
      await inbox.load();
      await inbox.load();
      expect(inbox.state.hasNext, isFalse);
      api.items = [notice('new'), ...api.items];
      await inbox.refreshHead();
      expect(inbox.state.page, 0);
      expect(inbox.state.hasNext, isTrue);
      await inbox.load();
      expect(
        inbox.state.items.map((n) => n.notificationId),
        api.items.map((n) => n.notificationId),
      );
    },
  );

  test(
    'failed catch-up keeps the last complete list and can retry without gaps',
    () async {
      api.items = List.generate(40, (i) => notice('old-$i'));
      await inbox.load();
      await inbox.load();
      await inbox.read('old-0');
      final before = inbox.state;
      api.items = [...List.generate(45, (i) => notice('new-$i')), ...api.items];
      api.failPage = 1;
      await inbox.refreshHead();
      expect(inbox.state.items, before.items);
      expect(inbox.state.page, before.page);
      expect(inbox.state.error, isNotNull);
      api.failPage = null;
      await inbox.refreshHead();
      expect(
        inbox.state.items.map((n) => n.notificationId),
        api.items.map((n) => n.notificationId),
      );
      expect(
        inbox.state.isRead(
          inbox.state.items.firstWhere((n) => n.notificationId == 'old-0'),
        ),
        isTrue,
      );
      expect(inbox.state.error, isNull);
    },
  );
}
