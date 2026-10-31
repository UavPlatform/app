import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/equipment_api.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../equipment_test_support.dart';
import '../test_support.dart';

void main() {
  test('an active loan response is not a confirmed return', () async {
    SharedPreferences.setMockInitialValues({});
    final client = HttpClient(
      TokenStorage(await SharedPreferences.getInstance()),
      adapter: StubAdapter(
        (_) async => jsonResponse(200, {
          'success': true,
          'data': equipmentLoan(status: 'APPROVED', withDrone: true),
        }),
      ),
    );
    addTearDown(() => client.dio.close());
    await expectLater(
      EquipmentApi(client).giveBack('loan1'),
      throwsA(isA<DispatchApiException>()),
    );
  });

  test(
    'apply sends model and stable attempt only; order optional',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
        adapter: StubAdapter((options) async {
          expect(options.path, '/equipment/pilot/borrows');
          expect(options.data, {
            'aircraftModelId': 1,
            'requestKey': 'stable-key',
          });
          return jsonResponse(200, {
            'success': true,
            'data': equipmentLoan(status: 'PENDING'),
          });
        }),
      );
      addTearDown(() => client.dio.close());
      expect(
        (await EquipmentApi(client).apply(
          aircraftModelId: 1,
          requestKey: 'stable-key',
        )).borrowId,
        'loan1',
      );
    },
  );

  test('missing return result cannot be shown as returned', () async {
    SharedPreferences.setMockInitialValues({});
    final client = HttpClient(
      TokenStorage(await SharedPreferences.getInstance()),
      adapter: StubAdapter((options) async {
        expect(options.path, '/equipment/pilot/borrows/loan1/return');
        return jsonResponse(200, {'success': true, 'data': null});
      }),
    );
    addTearDown(() => client.dio.close());
    await expectLater(
      EquipmentApi(client).giveBack('loan1'),
      throwsA(isA<DispatchApiException>()),
    );
  });
}
