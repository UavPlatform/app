import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/dispatch_live_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/pages/waybill/dispatch_live_panel.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/services/live_player.dart';

class LiveApiFake extends Fake implements DispatchLiveApi {
  ApiDispatchLiveStatusVO value = const ApiDispatchLiveStatusVO(
    configured: true,
    state: 'RUNNING',
    liveId: 'live',
    connectionId: 'connection',
    leaseExpiresAt: 100,
  );
  Completer<ApiDispatchLiveCredentialsVO>? pending;
  int watches = 0;
  int reads = 0;
  @override
  Future<ApiDispatchLiveStatusVO> status(String order) async {
    reads++;
    return value;
  }

  @override
  Future<ApiDispatchLiveCredentialsVO> watch(
    String order,
    String liveId,
  ) async {
    watches++;
    return pending?.future ??
        Future.value(
          const ApiDispatchLiveCredentialsVO(
            liveId: 'live',
            connectionId: 'connection',
            sdkAppId: 1,
            roomId: 'room',
            userId: 'viewer',
            publisherUserId: 'pilot',
            userSig: 'test-only',
            privateMapKey: 'test-room-only',
            expiresAt: 100,
          ),
        );
  }
}

class LiveEngineFake implements TrtcEngine {
  final stream = StreamController<TrtcEvent>.broadcast();
  final sessions = <LiveStreamSession>[];
  int exits = 0;
  @override
  Stream<TrtcEvent> get events => stream.stream;
  @override
  Future<void> enter(LiveStreamSession s) async {
    sessions.add(s);
  }

  @override
  Future<void> attachRemoteView(int id) async {}
  @override
  Future<void> detachRemoteView() async {}
  @override
  Future<void> exit() async {
    exits++;
  }
}

void main() {
  testWidgets(
    'room-bound preview waits for actual frame; fullscreen reuses player; stop only leaves viewing',
    (tester) async {
      final api = LiveApiFake();
      final engine = LiveEngineFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWithValue('account'),
            dispatchLiveApiProvider.overrideWithValue(api),
            dispatchLiveEngineFactoryProvider.overrideWithValue(() => engine),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DispatchLivePanel(
                orderId: 'order',
                useRealVideoView: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(engine.sessions, hasLength(1));
      expect(engine.sessions.single.privateMapKey, 'test-room-only');
      expect(engine.sessions.single.publisherUserId, 'pilot');
      expect(find.text('等待实际画面'), findsOneWidget);
      engine.stream.add(
        const TrtcEvent(TrtcEventKind.firstVideoFrame, remoteUserId: 'pilot'),
      );
      await tester.pumpAndSettle();
      expect(find.text('本单实时图传'), findsOneWidget);
      await tester.tap(find.byTooltip('放大本单直播'));
      await tester.pumpAndSettle();
      expect(find.text('本单直播'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(api.watches, 1);
      expect(engine.exits, 0);
      api.value = const ApiDispatchLiveStatusVO(
        configured: true,
        state: 'UNAVAILABLE',
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(
        api.reads,
        greaterThan(1),
        reason: 'live status must keep polling',
      );
      await tester.pump();
      expect(engine.exits, 1);
      expect(find.text('飞手尚未开启本单直播，暂无画面'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await engine.stream.close();
    },
  );
  testWidgets(
    'unconfigured service never creates a player or requests watch credentials',
    (tester) async {
      final api = LiveApiFake()
        ..value = const ApiDispatchLiveStatusVO(
          configured: false,
          state: 'UNAVAILABLE',
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWithValue('account'),
            dispatchLiveApiProvider.overrideWithValue(api),
            dispatchLiveEngineFactoryProvider.overrideWithValue(
              () => throw StateError('must not create'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DispatchLivePanel(
                orderId: 'order',
                useRealVideoView: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('本单直播服务尚未配置'), findsOneWidget);
      expect(api.watches, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'late credential after leaving the account scope cannot enter video room',
    (tester) async {
      final api = LiveApiFake()
        ..pending = Completer<ApiDispatchLiveCredentialsVO>();
      final engine = LiveEngineFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            waybillDraftScopeProvider.overrideWithValue('account'),
            dispatchLiveApiProvider.overrideWithValue(api),
            dispatchLiveEngineFactoryProvider.overrideWithValue(() => engine),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DispatchLivePanel(
                orderId: 'order',
                useRealVideoView: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(api.watches, 1);
      await tester.pumpWidget(const SizedBox());
      api.pending!.complete(
        const ApiDispatchLiveCredentialsVO(
          liveId: 'live',
          connectionId: 'connection',
        ),
      );
      await tester.pumpAndSettle();
      expect(engine.sessions, isEmpty);
      await engine.stream.close();
    },
  );
}
