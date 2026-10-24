import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/services/dispatch_realtime.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

void main() {
  test(
    'frames survive single-byte UTF8 chunks and CRLF; ignore comments and unknown events',
    () async {
      final bytes = utf8.encode(
        '\uFEFF: 在线\r\nevent: ready\r\ndata: {}\r\n\r\n'
        'event: unknown\ndata: {}\n\nevent: change\ndata: 第一行\ndata: 第二行\n\n'
        'event: heartbeat\ndata: {}\n\nevent: resync\ndata: {}\n\n',
      );
      expect(
        await decodeDispatchEvents(
          Stream.fromIterable(bytes.map((b) => [b])),
        ).toList(),
        ['ready', 'change', 'heartbeat', 'resync'],
      );
    },
  );

  test('incomplete and data-free events never invalidate snapshots', () async {
    final stream = Stream.value(
      utf8.encode('event: change\n\nevent: change\ndata: {}'),
    );
    expect(await decodeDispatchEvents(stream).toList(), isEmpty);
  });

  test(
    'oversized frames fail rather than accumulating without limit',
    () async {
      final stream = Stream.value(
        utf8.encode('event: change\ndata: ${'x' * 65537}\n\n'),
      );
      await expectLater(
        decodeDispatchEvents(stream).toList(),
        throwsFormatException,
      );
    },
  );

  test(
    'transport uses existing Bearer authentication and rejects non-SSE responses',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = TokenStorage(await SharedPreferences.getInstance());
      await storage.saveTokens(
        token: 'test-token',
        refreshToken: 'test-refresh',
      );
      var sse = true;
      final client = HttpClient(
        storage,
        adapter: StubAdapter((options) async {
          expect(options.path, '/dispatch/events');
          expect(options.queryParameters, isEmpty);
          expect(options.headers['Authorization'], 'Bearer test-token');
          expect(options.headers['Accept'], 'text/event-stream');
          return ResponseBody.fromString(
            sse ? 'event: ready\ndata: {}\n\n' : '{}',
            200,
            headers: {
              Headers.contentTypeHeader: [
                sse ? 'text/event-stream;charset=UTF-8' : 'application/json',
              ],
            },
          );
        }),
      );
      addTearDown(() => client.dio.close());
      final source = DioDispatchEventSource(client);
      expect(await source.connect(CancelToken()).toList(), ['ready']);
      sse = false;
      await expectLater(
        source.connect(CancelToken()).toList(),
        throwsFormatException,
      );
    },
  );
}
