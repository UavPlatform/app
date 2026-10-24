import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_notification_api.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

void main() {
  test(
    'unread and paged reads never acknowledge notifications, explicit read accepts null',
    () async {
      SharedPreferences.setMockInitialValues({});
      final paths = <String>[];
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
        adapter: StubAdapter((options) async {
          paths.add(options.path);
          expect(options.queryParameters.containsKey('userId'), isFalse);
          if (options.path.endsWith('/unread-count')) {
            return jsonResponse(200, {'success': true, 'data': 3});
          }
          if (options.path.endsWith('/read')) {
            return jsonResponse(200, {'success': true, 'data': null});
          }
          expect(options.queryParameters, {'page': '2'});
          return jsonResponse(200, {
            'success': true,
            'data': {
              'page': 2,
              'hasNext': false,
              'items': [],
              'unreadCount': 3,
            },
          });
        }),
      );
      addTearDown(() => client.dio.close());
      final api = DispatchNotificationApi(client);
      expect(await api.unread(), 3);
      expect((await api.list(2)).page, 2);
      expect(paths.where((p) => p.endsWith('/read')), isEmpty);
      await api.read('n1');
      expect(paths.last, '/dispatch/notifications/n1/read');
    },
  );
  test('invalid notification audience cannot produce a deep link', () async {
    SharedPreferences.setMockInitialValues({});
    final client = HttpClient(
      TokenStorage(await SharedPreferences.getInstance()),
      adapter: StubAdapter(
        (_) async => jsonResponse(200, {
          'success': true,
          'data': {
            'page': 0,
            'hasNext': false,
            'unreadCount': 0,
            'items': [
              {
                'notificationId': 'n',
                'orderId': 'o',
                'audience': 'ADMIN',
                'createdAt': 'now',
              },
            ],
          },
        }),
      ),
    );
    addTearDown(() => client.dio.close());
    await expectLater(
      DispatchNotificationApi(client).list(0),
      throwsA(isA<DispatchApiException>()),
    );
  });
}
