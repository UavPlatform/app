import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/dispatch_order_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../dispatch_order_test_support.dart';
import '../test_support.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  test(
    'create sends safe explicit fields, assessment and stable key, never amounts or local photos',
    () async {
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((options) async {
          expect(options.path, '/dispatch/orders');
          final input = options.data as Map;
          expect(input.keys.toSet(), {
            'assessmentId',
            'requestKey',
            'declarationAccepted',
            'waybill',
          });
          expect(input['requestKey'], 'stable-request-key');
          expect((input['waybill'] as Map)['fields'], {'category': '普通'});
          return jsonResponse(200, {'success': true, 'data': orderJson()});
        }),
      );
      addTearDown(() => client.dio.close());
      final result = await DispatchOrderApi(client).create(
        WaybillDraft(
          fields: {
            'category': '普通',
            'cargo.photo.local': 'C:/private/photo.jpg',
            'depositAmount': '1',
            'stage': 'PAID',
          },
        ),
        'assessment-id',
        'stable-request-key',
      );
      expect(result.awaitingDeposit, isTrue);
    },
  );
  test('null payment response cannot become a paid order', () async {
    final client = HttpClient(
      TokenStorage(prefs),
      adapter: StubAdapter(
        (_) async => jsonResponse(200, {'success': true, 'data': null}),
      ),
    );
    addTearDown(() => client.dio.close());
    await expectLater(
      DispatchOrderApi(client).pay('order'),
      throwsA(isA<DispatchApiException>()),
    );
  });
  test(
    'server assessment failure is preserved without automatic retry',
    () async {
      var calls = 0;
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((_) async {
          calls++;
          return jsonResponse(503, {
            'success': false,
            'errorCode': 'DISPATCH_UNAVAILABLE',
            'message': '未接入',
          });
        }),
      );
      addTearDown(() => client.dio.close());
      await expectLater(
        DispatchOrderApi(client).assess(WaybillDraft()),
        throwsA(
          isA<DispatchApiException>().having(
            (e) => e.code,
            'code',
            'DISPATCH_UNAVAILABLE',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test(
    'unknown stage or real-payment channel is not silently treated as demo success',
    () async {
      for (final value in [
        orderJson()..['stage'] = 'UNKNOWN',
        orderJson()..['paymentMode'] = 'WECHAT',
      ]) {
        final client = HttpClient(
          TokenStorage(prefs),
          adapter: StubAdapter(
            (_) async => jsonResponse(200, {'success': true, 'data': value}),
          ),
        );
        addTearDown(() => client.dio.close());
        await expectLater(
          DispatchOrderApi(client).get('order'),
          throwsA(isA<DispatchApiException>()),
        );
      }
    },
  );
}
