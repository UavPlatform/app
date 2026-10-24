import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_material_api.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/attachment_file_source.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

void main() {
  for (final failure in ['none', 'put', 'confirm']) {
    test(
      'signed upload keeps credentials separate and requires confirm: $failure',
      () async {
        SharedPreferences.setMockInitialValues({
          'jwt_token': makeJwt(userId: 7),
          'server_url': 'http://stub.local:8081',
        });
        var confirmations = 0;
        var uploads = 0;
        final client = HttpClient(
          TokenStorage(await SharedPreferences.getInstance()),
          adapter: StubAdapter((options) async {
            expect(options.headers['Authorization'], isNotNull);
            if (options.path.endsWith('/upload-ticket')) {
              expect(options.data['purpose'], 'PILOT_DELIVERY');
              return jsonResponse(200, {
                'success': true,
                'data': {
                  'materialId': 'material1',
                  'uploadUrl': 'https://store.local/object?signature=test',
                  'method': 'PUT',
                  'contentType': 'image/png',
                  'sizeBytes': 3,
                },
              });
            }
            confirmations++;
            expect(
              options.path,
              '/dispatch/orders/order1/materials/material1/confirm',
            );
            if (failure == 'confirm') {
              return jsonResponse(409, {'success': false, 'message': '对象未核验'});
            }
            return jsonResponse(200, {
              'success': true,
              'data': {
                'materialId': 'material1',
                'purpose': 'PILOT_DELIVERY',
                'uploadStatus': 'UPLOADED',
                'downloadUrl': 'https://store.local/get',
                'sizeBytes': 3,
              },
            });
          }),
        );
        final storage = Dio()
          ..httpClientAdapter = StubAdapter((options) async {
            uploads++;
            expect(options.method, 'PUT');
            expect(
              options.headers.keys.map((key) => key.toLowerCase()),
              isNot(contains('authorization')),
            );
            expect(options.contentType, 'image/png');
            expect(options.followRedirects, isFalse);
            return jsonResponse(failure == 'put' ? 403 : 200, {});
          });
        final api = DispatchMaterialApi(client, storage: storage);
        addTearDown(() {
          api.dispose();
          client.dio.close();
        });
        final result = api.upload(
          'order1',
          'PILOT_DELIVERY',
          UploadCandidate(
            fileName: 'proof.png',
            contentType: 'image/png',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        );
        if (failure == 'none') {
          expect((await result).id, 'material1');
        } else {
          await expectLater(result, throwsA(isA<DispatchApiException>()));
        }
        expect(uploads, 1);
        expect(confirmations, failure == 'put' ? 0 : 1);
      },
    );
  }
}
