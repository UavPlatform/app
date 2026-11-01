import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/pages/chat/chat_detail_page.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });

  testWidgets(
    'Send failures show their reason while retaining the existing draft controller',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': makeJwt(userId: 7),
        'server_url': 'http://stub.local:8081',
      });
      final prefs = await SharedPreferences.getInstance();
      final factory = ScriptedSocketFactory()..enqueueSocket(FakeChatSocket());
      final service = ChatWebSocketService(
        TokenStorage(prefs),
        socketFactory: factory.call,
      );
      var timeout = false;
      var sends = 0;
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((options) async {
          if (options.uri.path == '/chat/Message/send') {
            sends++;
            if (timeout)
              throw DioException(
                requestOptions: options,
                type: DioExceptionType.receiveTimeout,
              );
            return jsonResponse(200, {
              'success': false,
              'code': 403,
              'errorCode': 'NO_PERMISSION',
              'message': '订单已结单，只能查看聊天记录',
            });
          }
          return jsonResponse(200, {'success': true, 'data': []});
        }),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            httpClientProvider.overrideWithValue(client),
            chatWebSocketServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(
            home: ChatDetailPage(sessionId: 11, sessionName: '订单聊天'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller;
      await tester.enterText(find.byType(TextField), '货物已准备好');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(sends, 1);
      expect(find.text('订单已结单，只能查看聊天记录'), findsWidgets);
      expect(controller!.text, '货物已准备好');
      ScaffoldMessenger.of(
        tester.element(find.byType(TextField)),
      ).clearSnackBars();
      timeout = true;
      await tester.showKeyboard(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(sends, 2);
      expect(find.textContaining('操作结果尚未确认'), findsWidgets);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller,
        same(controller),
      );
      expect(controller.text, '货物已准备好');
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
      client.dio.close(force: true);
    },
  );
}
