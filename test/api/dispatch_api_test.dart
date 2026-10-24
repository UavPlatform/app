import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test(
    'fixed amounts come from server with no sum or client default',
    () async {
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((options) async {
          expect(options.path, '/dispatch/config');
          return jsonResponse(200, {
            'success': true,
            'data': {
              'currency': 'CNY',
              'depositAmount': 239.75,
              'pilotServiceFee': 87.50,
              'orderingEnabled': false,
            },
          });
        }),
      );
      addTearDown(() => client.dio.close());
      final value = await DispatchApi(client).settings();
      expect(value.depositAmount, 239.75);
      expect(value.pilotServiceFee, 87.50);
      expect(value.orderingEnabled, isFalse);
    },
  );

  test('missing settings do not fall back to example amounts', () async {
    final client = HttpClient(
      TokenStorage(prefs),
      adapter: StubAdapter(
        (_) async => jsonResponse(200, {'success': true, 'data': null}),
      ),
    );
    addTearDown(() => client.dio.close());
    await expectLater(
      DispatchApi(client).settings(),
      throwsA(isA<DispatchApiException>()),
    );
  });

  test(
    'no account draft is valid while save requires a server revision',
    () async {
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter(
          (_) async => jsonResponse(200, {'success': true, 'data': null}),
        ),
      );
      addTearDown(() => client.dio.close());
      final api = DispatchApi(client);
      expect(await api.loadDraft(), isNull);
      await expectLater(
        api.saveDraft(WaybillDraft(), null),
        throwsA(isA<DispatchApiException>()),
      );
    },
  );

  test('PUT uses generated DTO, revision and explicit safe fields', () async {
    final client = HttpClient(
      TokenStorage(prefs),
      adapter: StubAdapter((options) async {
        expect(options.method, 'PUT');
        expect(options.path, '/dispatch/waybill-draft');
        expect(options.data, {
          'schemaVersion': 1,
          'step': 1,
          'fields': {'category': '普通'},
          'expectedRevision': 7,
        });
        return jsonResponse(200, {
          'success': true,
          'data': {
            'schemaVersion': 1,
            'step': 1,
            'fields': {'category': '普通'},
            'revision': 8,
            'updatedAt': '2026-10-22T12:00:00',
          },
        });
      }),
    );
    addTearDown(() => client.dio.close());
    final draft = WaybillDraft(
      step: 1,
      fields: {
        'category': '普通',
        'cargo.photo.id': 'C:/private/photo.jpg',
        'totalAmount': '1',
        'orderStatus': 'PAID',
      },
    );
    final value = await DispatchApi(client).saveDraft(draft, 7);
    expect(value.revision, 8);
    expect(value.draft.fields, {'category': '普通'});
  });

  test(
    'conflict is preserved and never retried or reported as success',
    () async {
      var calls = 0;
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((_) async {
          calls++;
          return jsonResponse(409, {
            'success': false,
            'errorCode': 'WAYBILL_DRAFT_CONFLICT',
            'message': '账号草稿已更新',
          });
        }),
      );
      addTearDown(() => client.dio.close());
      await expectLater(
        DispatchApi(client).saveDraft(WaybillDraft(), 2),
        throwsA(
          isA<DispatchApiException>().having(
            (e) => e.code,
            'code',
            'WAYBILL_DRAFT_CONFLICT',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
}
