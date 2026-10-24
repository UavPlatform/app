import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/dispatch_order_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';
import '../dispatch_order_test_support.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  test(
    'release accepts success=true data=null and sends assignment epoch only',
    () async {
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((options) async {
          expect(options.path, '/dispatch/pilot/orders/order/release');
          expect(options.data, {'assignmentVersion': 7});
          return jsonResponse(200, {'success': true, 'data': null});
        }),
      );
      addTearDown(() => client.dio.close());
      await DispatchOrderApi(client).release('order', 7);
    },
  );
  test(
    'claim preserves conflict without replay and never invents a winner',
    () async {
      var calls = 0;
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((options) async {
          calls++;
          expect(options.data, {'offerRevision': 12});
          return jsonResponse(409, {
            'success': false,
            'errorCode': 'DISPATCH_ASSIGNMENT_CHANGED',
            'message': '已被接走',
          });
        }),
      );
      addTearDown(() => client.dio.close());
      await expectLater(
        DispatchOrderApi(client).claim('order', 12),
        throwsA(
          isA<DispatchApiException>().having(
            (e) => e.code,
            'code',
            'DISPATCH_ASSIGNMENT_CHANGED',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test(
    'successful claim consumes server pilot and assignment version',
    () async {
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter(
          (_) async => jsonResponse(200, {
            'success': true,
            'data': orderJson(stage: 'PILOT_PREPARING', funds: 'PAID')
              ..['assignedPilotId'] = 77
              ..['assignmentVersion'] = 3,
          }),
        ),
      );
      addTearDown(() => client.dio.close());
      final order = await DispatchOrderApi(client).claim('order', 12);
      expect(order.preparing, isTrue);
      expect(order.data.assignedPilotId, 77);
      expect(order.data.assignmentVersion, 3);
    },
  );
}
