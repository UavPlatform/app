import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/dispatch_realtime.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

void main() {
  test(
    'cancelling established SSE completes normally without an unhandled cancellation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final body = StreamController<Uint8List>();
      final ready = Completer<void>();
      final errors = <Object>[];
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
        adapter: StubAdapter(
          (_) async => ResponseBody(
            body.stream,
            200,
            headers: {
              Headers.contentTypeHeader: ['text/event-stream'],
            },
          ),
        ),
      );
      final token = CancelToken();
      final subscription = DioDispatchEventSource(client).connect(token).listen(
        (event) {
          if (event == 'ready' && !ready.isCompleted) ready.complete();
        },
        onError: errors.add,
      );
      body.add(Uint8List.fromList(utf8.encode('event: ready\ndata: {}\n\n')));
      await ready.future;
      token.cancel('Inactive');
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await body.close();
      client.dio.close();
      expect(errors, isEmpty);
    },
  );

  test(
    'cancelling while waiting for SSE headers is normal completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final headers = Completer<ResponseBody>();
      final started = Completer<void>();
      final errors = <Object>[];
      final done = Completer<void>();
      final client = HttpClient(
        TokenStorage(await SharedPreferences.getInstance()),
        adapter: StubAdapter((_) {
          started.complete();
          return headers.future;
        }),
      );
      final token = CancelToken();
      DioDispatchEventSource(client)
          .connect(token)
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await started.future;
      token.cancel('Inactive');
      await done.future;
      headers.complete(
        ResponseBody.fromString(
          '',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/event-stream'],
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      client.dio.close();
      expect(errors, isEmpty);
    },
  );
}
