import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/chat_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/message_vo.dart';
import 'package:uav_pilot_app/providers/chat_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

MessageVo message(String id, int timestamp, {int session = 11}) => MessageVo(
  msgId: id,
  sessionId: session,
  msgType: 0,
  fromUserId: 8,
  timestamp: timestamp,
  content: id,
);

void main() {
  test('REQ-APP-001: self messages and replayed pushes do not inflate unread; failed read keeps badge', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var readFails = true;
    final client = HttpClient(TokenStorage(prefs), adapter: StubAdapter((options) async {
      if (options.uri.path.endsWith('/read')) return jsonResponse(readFails ? 503 : 200, {'success': !readFails});
      return jsonResponse(200, {'success': true, 'data': [
        {'id': 11, 'name': '飞手', 'type': 0, 'userIds': [7, 8], 'unreadCount': 4}
      ]});
    }));
    final pushes = StreamController<MessageVo>.broadcast(sync: true);
    final resync = StreamController<void>.broadcast(sync: true);
    final notifier = SessionListNotifier(ChatApi(client), client, pushes.stream, resync.stream, viewerUserId: 7);
    addTearDown(() { notifier.dispose(); pushes.close(); resync.close(); });
    await pumpEventQueue();
    pushes.add(MessageVo(msgId: 'self', sessionId: 11, msgType: 0, fromUserId: 7, timestamp: 1, content: 'self'));
    expect(notifier.state.sessions.single.unreadCount, 4);
    pushes.add(message('peer', 2));
    pushes.add(message('peer', 2));
    expect(notifier.state.sessions.single.unreadCount, 5);
    await notifier.markSessionRead(11);
    expect(notifier.state.sessions.single.unreadCount, 5);
    readFails = false;
    await notifier.markSessionRead(11);
    expect(notifier.state.sessions.single.unreadCount, 0);
  });
  test(
    'Slow history cannot overwrite realtime arrivals; dedupe and serialize refreshes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final pending = <Completer<ResponseBody>>[];
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((_) {
          final request = Completer<ResponseBody>();
          pending.add(request);
          return request.future;
        }),
      );
      final pushes = StreamController<MessageVo>.broadcast(sync: true);
      final resync = StreamController<void>.broadcast(sync: true);
      final notifier = MessageListNotifier(
        ChatApi(client),
        11,
        pushes.stream,
        resync.stream,
      );
      addTearDown(() {
        notifier.dispose();
        pushes.close();
        resync.close();
      });
      await pumpEventQueue();
      final concurrentLoad = notifier.load();
      pushes.add(message('live', 2));
      pushes.add(message('live', 2));
      pushes.add(message('another-session', 3, session: 22));
      expect(pending, hasLength(1));
      pending.first.complete(
        jsonResponse(200, {
          'success': true,
          'data': [
            {
              'msgId': 'old',
              'sessionId': 11,
              'timestamp': 1,
              'payload': {'text': 'old'},
            },
          ],
        }),
      );
      await concurrentLoad;
      expect(notifier.state.messages.map((m) => m.msgId), ['old', 'live']);
      expect(notifier.state.loading, isFalse);
      final refresh = notifier.load(silent: true);
      await pumpEventQueue();
      expect(
        notifier.state.loading,
        isFalse,
        reason: 'Background sync keeps existing bubbles visible',
      );
      pending.last.complete(
        jsonResponse(500, {'success': false, 'message': 'offline'}),
      );
      await refresh;
      expect(notifier.state.messages.map((m) => m.msgId), ['old', 'live']);
      expect(notifier.state.error, isNotNull);
    },
  );

  testWidgets('Order conversation discovers new sessions on push and resync', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    final client = HttpClient(
      TokenStorage(prefs),
      adapter: StubAdapter((_) async {
        calls++;
        return jsonResponse(200, {
          'success': true,
          'data': calls == 1
              ? []
              : [
                  {
                    'sessionId': 11,
                    'taskNum': 'T-1',
                    'riderId': 8,
                    'unreadCount': calls - 1,
                    'lastMessage': 'hello',
                  },
                ],
        });
      }),
    );
    final pushes = StreamController<MessageVo>.broadcast(sync: true);
    final resync = StreamController<void>.broadcast(sync: true);
    final notifier = TaskChatSessionsNotifier(
      ChatApi(client),
      'T-1',
      pushes.stream,
      resync.stream,
    );
    await tester.pumpAndSettle();
    expect(notifier.state.sessions, isEmpty);
    pushes.add(message('new-session', 1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(notifier.state.sessions.single.sessionId, 11);
    expect(notifier.state.sessions.single.unreadCount, 1);
    resync.add(null);
    await tester.pumpAndSettle();
    expect(notifier.state.sessions.single.unreadCount, 2);
    notifier.dispose();
    await pushes.close();
    await resync.close();
  });
}
