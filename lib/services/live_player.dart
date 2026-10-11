// 直播播放器抽象与生命周期控制（t38）。
// TrtcEngine 封装腾讯云 TRTC Flutter SDK（tencent_trtc_cloud）平台调用；
// LivePlayerController 管理进房/画面绑定/退出生命周期，可注入假引擎测试。

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';

/// 一次观看的进房参数（凭证来自 /live/get 响应值，不自报身份）。
class LiveStreamSession {
  final int sdkAppId;
  final String strRoomId;
  final String userId;
  final String userSig;

  const LiveStreamSession({
    required this.sdkAppId,
    required this.strRoomId,
    required this.userId,
    required this.userSig,
  });
}

enum LivePlayerPhase { idle, entering, playing, exited }

enum TrtcEventKind { remoteVideoAvailable, remoteVideoUnavailable, exited }

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

/// 腾讯云 TRTC 引擎实现（观众角色，strRoomId 字符串房间，自动收流）。
class TrtcEngineImpl implements TrtcEngine {
  final _events = StreamController<TrtcEvent>.broadcast();
  TRTCCloud? _cloud;
  TRTCCloudListener? _listener;
  String? _firstRemoteUserId;
  int? _viewId;

  @override
  Stream<TrtcEvent> get events => _events.stream;

  @override
  Future<void> enter(LiveStreamSession session) async {
    final cloud = await TRTCCloud.sharedInstance();
    _cloud = cloud;
    final listener = TRTCCloudListener(
      onUserVideoAvailable: (userId, available) {
        if (available && _firstRemoteUserId == null && userId.isNotEmpty) {
          _firstRemoteUserId = userId;
          _events.add(
            const TrtcEvent(TrtcEventKind.remoteVideoAvailable),
          );
          // 画面已就绪则立即绑定渲染
          final viewId = _viewId;
          if (viewId != null) {
            _bindView(viewId);
          }
        }
        if (!available) {
          _events.add(
            const TrtcEvent(TrtcEventKind.remoteVideoUnavailable),
          );
        }
      },
      onExitRoom: (reason) {
        _events.add(const TrtcEvent(TrtcEventKind.exited));
      },
    );
    _listener = listener;
    cloud.registerListener(listener);
    cloud.enterRoom(
      TRTCParams(
        sdkAppId: session.sdkAppId,
        userId: session.userId,
        userSig: session.userSig,
        strRoomId: session.strRoomId,
        roomId: 0,
        role: TRTCRoleType.audience,
      ),
      TRTCAppScene.live,
    );
  }

  void _bindView(int viewId) {
    final userId = _firstRemoteUserId;
    if (userId == null) return;
    _cloud?.startRemoteView(
      userId,
      TRTCVideoStreamType.big,
      viewId,
    );
  }

  @override
  Future<void> attachRemoteView(int viewId) async {
    _viewId = viewId;
    _bindView(viewId);
  }

  @override
  Future<void> detachRemoteView() async {
    final userId = _firstRemoteUserId;
    if (userId != null) {
      _cloud?.stopRemoteView(
        userId,
        TRTCVideoStreamType.big,
      );
    }
    _viewId = null;
  }

  @override
  Future<void> exit() async {
    _cloud?.exitRoom();
    final listener = _listener;
    if (listener != null) {
      _cloud?.unRegisterListener(listener);
    }
    _listener = null;
    _cloud = null;
    _firstRemoteUserId = null;
  }
}

/// 播放器生命周期控制：idle → entering → playing → exited。
/// 直播结束（远端停流/退出事件）通过 onEnded 上抛，由页面展示并退出。
class LivePlayerController {
  final TrtcEngine engine;
  LivePlayerPhase _phase = LivePlayerPhase.idle;
  final _phaseController = StreamController<LivePlayerPhase>.broadcast();
  final _endedController = StreamController<void>.broadcast();
  StreamSubscription<TrtcEvent>? _eventSub;

  LivePlayerPhase get phase => _phase;
  Stream<LivePlayerPhase> get phaseStream => _phaseController.stream;

  /// 直播结束信号（远端停流或房间被解散）
  Stream<void> get onEnded => _endedController.stream;

  LivePlayerController({TrtcEngine? engine}) : engine = engine ?? TrtcEngineImpl();

  bool get isLive => _phase == LivePlayerPhase.playing;

  Future<void> enter(LiveStreamSession session) async {
    if (_phase != LivePlayerPhase.idle && _phase != LivePlayerPhase.exited) {
      return;
    }
    _setPhase(LivePlayerPhase.entering);
    _eventSub?.cancel();
    _eventSub = engine.events.listen(_onEngineEvent);
    try {
      await engine.enter(session);
      _setPhase(LivePlayerPhase.playing);
    } catch (_) {
      _setPhase(LivePlayerPhase.exited);
      rethrow;
    }
  }

  /// 视频渲染视图创建后绑定画面（远端可用性由引擎事件驱动）。
  Future<void> attachView(int viewId) async {
    if (_phase != LivePlayerPhase.playing) return;
    await engine.attachRemoteView(viewId);
  }

  /// 退出观看：停绑画面并退房释放资源（幂等）。
  Future<void> leave() async {
    if (_phase == LivePlayerPhase.exited || _phase == LivePlayerPhase.idle) {
      return;
    }
    _eventSub?.cancel();
    _eventSub = null;
    await engine.detachRemoteView();
    await engine.exit();
    _setPhase(LivePlayerPhase.exited);
  }

  void _onEngineEvent(TrtcEvent event) {
    switch (event.kind) {
      case TrtcEventKind.remoteVideoUnavailable:
        // 主播停流/掉线：视为直播结束信号（t38⑤）
        _endedController.add(null);
        break;
      case TrtcEventKind.exited:
        _endedController.add(null);
        break;
      case TrtcEventKind.remoteVideoAvailable:
        break;
    }
  }

  void _setPhase(LivePlayerPhase phase) {
    _phase = phase;
    _phaseController.add(phase);
  }

  void dispose() {
    _eventSub?.cancel();
    _phaseController.close();
    _endedController.close();
  }
}

/// 直播引擎提供者（页面默认注入真实 TRTC 引擎；测试可覆盖）。
final liveEngineProvider = Provider<TrtcEngine>((ref) => TrtcEngineImpl());
