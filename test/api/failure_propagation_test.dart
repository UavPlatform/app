import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/chat_api.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/dispatch_requests.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import 'package:uav_pilot_app/utils/failure_message.dart';

import '../test_support.dart';

void main() {
  test(
    'Chat business rejection keeps its error code through the API adapter',
    () async {
      SharedPreferences.setMockInitialValues({
        'server_url': 'http://stub.local:8081',
      });
      final prefs = await SharedPreferences.getInstance();
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter(
          (_) async => jsonResponse(200, {
            'success': false,
            'code': 403,
            'errorCode': 'NO_PERMISSION',
            'message': '操作失败',
          }),
        ),
      );
      addTearDown(() => client.dio.close(force: true));
      final result = await ChatApi(
        client,
      ).sendMessage(sessionId: 11, content: '测试消息');
      expect(result.success, isFalse);
      expect(result.errorCode, 'NO_PERMISSION');
      expect(resultFailureMessage(result, fallback: '发送失败'), contains('权限'));
    },
  );
  test(
    'Dispatch HTTP conflicts preserve code and display the relevant recovery action',
    () async {
      final request = RequestOptions(path: '/stub');
      await expectLater(
        dispatchRequest(
          () async => throw DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: 409,
              data: {
                'success': false,
                'errorCode': 'ASSESSMENT_INVALID',
                'message': '操作失败',
              },
            ),
          ),
        ),
        throwsA(
          isA<DispatchApiException>()
              .having((e) => e.code, 'code', 'ASSESSMENT_INVALID')
              .having((e) => e.message, 'message', contains('重新评估')),
        ),
      );
    },
  );
}
