import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_nearby_api.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/dispatch_location.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';
import '../services/dispatch_location_test.dart' show validFix;

void main() {
  test(
    'location activation upload and stop retain session scope without user or contact fields',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
        adapter: StubAdapter((options) async {
          if (options.path.endsWith('/position-session')) {
            return jsonResponse(200, {'success': true, 'data': 'session-one'});
          }
          if (options.method == 'DELETE') {
            expect(options.queryParameters, {'sessionKey': 'session-one'});
            return jsonResponse(200, {'success': true, 'data': null});
          }
          expect(
            (options.data as Map).keys,
            unorderedEquals([
              'sessionKey',
              'latitude',
              'longitude',
              'accuracyMeters',
              'capturedAt',
              'coordinateSystem',
              'mocked',
            ]),
          );
          expect(options.data['sessionKey'], 'session-one');
          final now = DateTime.now().millisecondsSinceEpoch;
          return jsonResponse(200, {
            'success': true,
            'data': {
              'receivedAt': now,
              'expiresAt': now + 300000,
              'accuracyMeters': 12,
              'coordinateSystem': 'GCJ02',
            },
          });
        }),
      );
      addTearDown(() => client.dio.close());
      final api = DispatchNearbyApi(client);
      final key = await api.begin();
      expect(
        (await api.update(
          DispatchLocationFix.fromMap(validFix()),
          key,
        )).coordinateSystem,
        'GCJ02',
      );
      await api.clear(key);
    },
  );
  test(
    'nearby response never falls back to all orders on invalid location state',
    () async {
      SharedPreferences.setMockInitialValues({});
      var raw = <String, dynamic>{
        'items': [],
        'page': 0,
        'hasNext': false,
        'radiusKm': 10,
        'locationState': 'LOCATION_REQUIRED',
      };
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
        adapter: StubAdapter(
          (_) async => jsonResponse(200, {'success': true, 'data': raw}),
        ),
      );
      addTearDown(() => client.dio.close());
      final api = DispatchNearbyApi(client);
      expect((await api.hall(0)).locationState, 'LOCATION_REQUIRED');
      raw = {...raw, 'locationState': 'UNKNOWN'};
      await expectLater(api.hall(0), throwsA(isA<DispatchApiException>()));
      raw = {
        ...raw,
        'locationState': 'READY',
        'items': [
          {
            'distanceMeters': 10001,
            'offer': {'orderId': 'one', 'offerRevision': 1, 'fields': {}},
          },
        ],
      };
      await expectLater(api.hall(0), throwsA(isA<DispatchApiException>()));
    },
  );
}
