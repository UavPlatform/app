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

Map<String, dynamic> envelope(String id) => {
  'msgId': id,
  'sessionId': 11,
  'fromUserId': 8,
  'timestamp': 100,
  'msgType': 'CHAT',
  'payload': {'text': id},
};

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });
  testWidgets('Compact order chat keeps drafts and read-only history usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    SharedPreferences.setMockInitialValues({
      'jwt_token': makeJwt(userId: 7),
      'server_url': 'http://stub.local:8081',
    });
    final prefs = await SharedPreferences.getInstance();
    final socket = FakeChatSocket();
    final factory = ScriptedSocketFactory()..enqueueSocket(socket);
    final service = ChatWebSocketService(
      TokenStorage(prefs),
      socketFactory: factory.call,
    );
    final client = HttpClient(
      TokenStorage(prefs),
      adapter: StubAdapter(
        (options) async => jsonResponse(200, {'success': true, 'data': []}),
      ),
    );
    Widget page({bool readOnly = false}) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(client),
        chatWebSocketServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        home: ChatDetailPage(
          sessionId: 11,
          sessionName: '订单聊天',
          orderId: '55689f01234567890123458947',
          orderStatus: '运输中',
          readOnly: readOnly,
        ),
      ),
    );
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('运单 55689f…8947'), findsOneWidget);
    expect(find.text('运输中'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('到达后请电话联系我'));
    await tester.tap(find.text('到达后请电话联系我'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '到达后请电话联系我',
    );
    socket.pushMessage(envelope('对方的长消息' * 20));
    socket.pushMessage({...envelope('我的消息'), 'fromUserId': 7});
    await tester.pumpAndSettle();
    expect(find.text('我的消息'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpWidget(page(readOnly: true));
    await tester.pumpAndSettle();
    expect(find.text('仅供查看'), findsOneWidget);
    expect(find.text('我的消息'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('发送消息'), findsNothing);
    expect(find.text('货物已准备好'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
  testWidgets(
    'Instant push, missed-push fallback, manual refresh and foreground resync',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': makeJwt(userId: 7),
        'server_url': 'http://stub.local:8081',
      });
      final prefs = await SharedPreferences.getInstance();
      final socket = FakeChatSocket();
      final factory = ScriptedSocketFactory()..enqueueSocket(socket);
      final service = ChatWebSocketService(
        TokenStorage(prefs),
        socketFactory: factory.call,
      );
      var reads = 0;
      var sends = 0;
      var serverMessages = <Map<String, dynamic>>[];
      final client = HttpClient(
        TokenStorage(prefs),
        adapter: StubAdapter((options) async {
          if (options.uri.path == '/chat/Message/send') {
            sends++;
            return jsonResponse(200, {'success': false, 'message': '发送失败'});
          }
          if (options.uri.path == '/chat/Message/messages/11') {
            reads++;
            return jsonResponse(200, {'success': true, 'data': serverMessages});
          }
          if (options.uri.path == '/chat/session/list') {
            return jsonResponse(200, {'success': true, 'data': []});
          }
          return jsonResponse(200, {'success': true});
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
            home: ChatDetailPage(sessionId: 11, sessionName: '飞手甲'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('暂无沟通消息'), findsOneWidget);
      await tester.tap(find.text('货物已准备好'));
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.controller!.text, '货物已准备好');
      expect(input.controller!.selection.baseOffset, '货物已准备好'.length);
      expect(input.focusNode!.hasFocus, isTrue);
      expect(sends, 0, reason: 'Quick phrases only fill the existing draft');
      await tester.tap(find.byTooltip('发送消息'));
      await tester.pumpAndSettle();
      expect(sends, 1);
      expect(input.controller!.text, '货物已准备好');
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('消息发送未完成，请稍后重试'),
        ),
        findsOneWidget,
      );
      input.controller!.clear();
      input.focusNode!.unfocus();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      socket.pushMessage(envelope('即时回复'));
      socket.pushMessage(envelope('即时回复'));
      await tester.pumpAndSettle();
      expect(find.text('即时回复'), findsOneWidget);
      serverMessages = [
        envelope('即时回复'),
        {...envelope('漏推送回复'), 'timestamp': 101},
      ];
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('漏推送回复'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      serverMessages = [envelope('下拉刷新回复')];
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('下拉刷新回复'), findsOneWidget);
      serverMessages = [envelope('手动刷新回复')];
      await tester.tap(find.byTooltip('刷新消息'));
      await tester.pumpAndSettle();
      expect(find.text('手动刷新回复'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final beforePause = reads;
      await tester.pump(const Duration(seconds: 20));
      expect(reads, beforePause);
      serverMessages = [envelope('回到前台回复')];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('回到前台回复'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      final afterLeave = reads;
      await tester.pump(const Duration(seconds: 10));
      expect(
        reads,
        afterLeave,
        reason: 'Leaving chat cancels background requests',
      );
      service.dispose();
    },
  );
}
