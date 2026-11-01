// 腾讯云 TRTC 引擎实现。仅由 trtc_engine_factory 在非 SKIP_TRTC 且受支持平台上引用。

import 'dart:async';

import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';

import 'live_player.dart';

/// 腾讯云 TRTC 引擎实现（观众角色，strRoomId 字符串房间，自动收流）。
class TrtcEngineImpl implements TrtcEngine {
  final _events = StreamController<TrtcEvent>.broadcast();
  TRTCCloud? _cloud;
  TRTCCloudListener? _listener;
  String? _firstRemoteUserId;
  int? _viewId;
  String? _expectedPublisher;
  int _generation = 0;

  @override
  Stream<TrtcEvent> get events => _events.stream;

  @override
  Future<void> enter(LiveStreamSession session) async {
    final generation = ++_generation;
    final cloud = await TRTCCloud.sharedInstance();
    if (generation != _generation) return;
    _expectedPublisher = session.publisherUserId;
    _cloud = cloud;
    final listener = TRTCCloudListener(
      onUserVideoAvailable: (userId, available) {
        if (generation != _generation ||
            (_expectedPublisher != null && userId != _expectedPublisher)) {
          return;
        }
        if (available && _firstRemoteUserId == null && userId.isNotEmpty) {
          _firstRemoteUserId = userId;
          _events.add(const TrtcEvent(TrtcEventKind.remoteVideoAvailable));
          final viewId = _viewId;
          if (viewId != null) {
            _bindView(viewId);
          }
        }
        if (!available && userId == _firstRemoteUserId) {
          _events.add(const TrtcEvent(TrtcEventKind.remoteVideoUnavailable));
        }
      },
      onFirstVideoFrame: (userId, streamType, width, height) {
        if (generation == _generation && userId == _firstRemoteUserId) {
          _events.add(
            TrtcEvent(TrtcEventKind.firstVideoFrame, remoteUserId: userId),
          );
        }
      },
      onError: (code, message) {
        if (generation == _generation) {
          _events.add(const TrtcEvent(TrtcEventKind.exited));
        }
      },
      onExitRoom: (reason) {
        if (generation != _generation) return;
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
        privateMapKey: session.privateMapKey ?? '',
      ),
      TRTCAppScene.live,
    );
  }

  void _bindView(int viewId) {
    final userId = _firstRemoteUserId;
    if (userId == null) return;
    _cloud?.startRemoteView(userId, TRTCVideoStreamType.big, viewId);
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
      _cloud?.stopRemoteView(userId, TRTCVideoStreamType.big);
    }
    _viewId = null;
  }

  @override
  Future<void> exit() async {
    _generation++;
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
