// 直播播放器抽象与生命周期控制（t38）。
// 真实 TRTC 实现见 live_player_trtc.dart；无原生 SDK / SKIP_TRTC 时走 stub。

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trtc_engine_factory.dart';

/// 一次观看的进房参数（凭证来自 /live/get 响应值，不自报身份）。
class LiveStreamSession {
  final int sdkAppId;
  final String strRoomId;
  final String userId;
  final String userSig;
  final String? privateMapKey;
  final String? publisherUserId;

  const LiveStreamSession({
    required this.sdkAppId,
    required this.strRoomId,
    required this.userId,
    required this.userSig,
    this.privateMapKey,
    this.publisherUserId,
  });
}

enum LivePlayerPhase { idle, entering, playing, exited }

enum TrtcEventKind {
  remoteVideoAvailable,
  remoteVideoUnavailable,
  firstVideoFrame,
  exited,
}

class TrtcEvent {
  final TrtcEventKind kind;
  final String? remoteUserId;

  const TrtcEvent(this.kind, {this.remoteUserId});
}

/// TRTC 平台引擎抽象：LivePlayerController 通过它驱动 SDK，
/// 测试注入假实现即可覆盖生命周期而无需真实平台通道。
abstract class TrtcEngine {
  Stream<TrtcEvent> get events;

  Future<void> enter(LiveStreamSession session);

  Future<void> attachRemoteView(int viewId);

  Future<void> detachRemoteView();

  Future<void> exit();
}

/// 无原生 TRTC / 集成测试用的空引擎（进房即成功，不拉流）。
class StubTrtcEngine implements TrtcEngine {
  final _events = StreamController<TrtcEvent>.broadcast();

  @override
  Stream<TrtcEvent> get events => _events.stream;

  @override
  Future<void> enter(LiveStreamSession session) async {}

  @override
  Future<void> attachRemoteView(int viewId) async {}

  @override
  Future<void> detachRemoteView() async {}

  @override
  Future<void> exit() async {}

  void dispose() {
    _events.close();
  }
}

/// 播放器生命周期控制：idle → entering → playing → exited。
class LivePlayerController {
  final TrtcEngine engine;
  LivePlayerPhase _phase = LivePlayerPhase.idle;
  final _phaseController = StreamController<LivePlayerPhase>.broadcast();
  final _endedController = StreamController<void>.broadcast();
  StreamSubscription<TrtcEvent>? _eventSub;
  int _operation = 0;
  bool _disposed = false;

  LivePlayerPhase get phase => _phase;
  Stream<LivePlayerPhase> get phaseStream => _phaseController.stream;

  /// 直播结束信号（远端停流或房间被解散）
  Stream<void> get onEnded => _endedController.stream;

  LivePlayerController({TrtcEngine? engine})
    : engine = engine ?? createTrtcEngine();

  bool get isLive => _phase == LivePlayerPhase.playing;

  Future<void> enter(LiveStreamSession session) async {
    if (_phase != LivePlayerPhase.idle && _phase != LivePlayerPhase.exited) {
      return;
    }
    final operation = ++_operation;
    if (_disposed) return;
    _setPhase(LivePlayerPhase.entering);
    _eventSub?.cancel();
    _eventSub = engine.events.listen(_onEngineEvent);
    try {
      await engine.enter(session);
      if (_disposed || operation != _operation) return;
      _setPhase(LivePlayerPhase.playing);
    } catch (_) {
      _setPhase(LivePlayerPhase.exited);
      rethrow;
    }
  }

  Future<void> attachView(int viewId) async {
    if (_phase != LivePlayerPhase.playing) return;
    await engine.attachRemoteView(viewId);
  }

  Future<void> leave() async {
    _operation++;
    if (_phase == LivePlayerPhase.exited || _phase == LivePlayerPhase.idle) {
      return;
    }
    _eventSub?.cancel();
    _eventSub = null;
    try {
      await engine.detachRemoteView();
    } finally {
      try {
        await engine.exit();
      } finally {
        _setPhase(LivePlayerPhase.exited);
      }
    }
  }

  void _onEngineEvent(TrtcEvent event) {
    switch (event.kind) {
      case TrtcEventKind.remoteVideoUnavailable:
        _endedController.add(null);
        break;
      case TrtcEventKind.exited:
        _endedController.add(null);
        break;
      case TrtcEventKind.remoteVideoAvailable:
      case TrtcEventKind.firstVideoFrame:
        break;
    }
  }

  void _setPhase(LivePlayerPhase phase) {
    _phase = phase;
    if (_disposed) return;
    _phaseController.add(phase);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operation++;
    _eventSub?.cancel();
    _phaseController.close();
    _endedController.close();
  }
}

/// 直播引擎提供者（页面默认注入；测试可覆盖）。
final liveEngineProvider = Provider<TrtcEngine>((ref) => createTrtcEngine());
