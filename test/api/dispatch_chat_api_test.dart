import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_chat_api.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

void main() {
  test(
    'only order and expected assignment are sent; invalid or mismatched sessions are rejected',
    () async {
      SharedPreferences.setMockInitialValues({});
      var payload = <String, dynamic>{
        'sessionId': 42,
        'orderId': 'order-1',
        'assignmentVersion': 3,
      };
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
        adapter: StubAdapter((options) async {
          expect(options.path, '/dispatch/orders/order-1/chat');
          expect(options.data, {'assignmentVersion': 3});
          return jsonResponse(200, {'success': true, 'data': payload});
        }),
      );
      addTearDown(() => client.dio.close());
      final api = DispatchChatApi(client);
      expect(await api.open('order-1', 3), 42);
      for (final bad in [
        {'sessionId': 42, 'orderId': 'another-order', 'assignmentVersion': 3},
        {'sessionId': 42, 'orderId': 'order-1', 'assignmentVersion': 2},
        {'sessionId': 0, 'orderId': 'order-1', 'assignmentVersion': 3},
        <String, dynamic>{},
      ]) {
        payload = bad;
        await expectLater(
          api.open('order-1', 3),
          throwsA(isA<DispatchApiException>()),
        );
      }
    },
  );
}
