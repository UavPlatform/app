import '../../utils/failure_message.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';
import '../../api/dispatch_live_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../services/live_player.dart';

final dispatchLiveApiProvider = Provider(
  (ref) => DispatchLiveApi(ref.watch(httpClientProvider)),
);
final dispatchLiveEngineFactoryProvider = Provider<TrtcEngine Function()>(
  (ref) =>
      () => TrtcEngineImpl(),
);

class DispatchLivePanel extends ConsumerWidget {
  const DispatchLivePanel({
    super.key,
    required this.orderId,
    this.useRealVideoView = true,
    this.showFlightHeading = false,
  });
  final String orderId;
  final bool useRealVideoView, showFlightHeading;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(waybillDraftScopeProvider);
    if (scope == null) {
      return const Text('登录后可观看本单直播');
    }
    return _LivePanel(
      key: ValueKey('$scope:$orderId'),
      orderId: orderId,
      api: ref.watch(dispatchLiveApiProvider),
      factory: ref.watch(dispatchLiveEngineFactoryProvider),
      useRealVideoView: useRealVideoView,
      showFlightHeading: showFlightHeading,
    );
  }
}

class _LivePanel extends StatefulWidget {
  const _LivePanel({
    super.key,
    required this.orderId,
    required this.api,
    required this.factory,
    required this.useRealVideoView,
    required this.showFlightHeading,
  });
  final String orderId;
  final DispatchLiveApi api;
  final TrtcEngine Function() factory;
  final bool useRealVideoView, showFlightHeading;
  @override
  State<_LivePanel> createState() => _LivePanelState();
}

class _LivePanelState extends State<_LivePanel> with WidgetsBindingObserver {
  Timer? _timer;
  bool _busy = false, _foreground = true, _rendered = false;
  String _message = '正在读取本单直播状态';
  String? _liveId, _failedId;
  int? _previewId;
  LivePlayerController? _player;
  StreamSubscription<TrtcEvent>? _events;
  StreamSubscription<void>? _ended;
  DialogRoute<void>? _fullRoute;
  NavigatorState? _fullNavigator;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_poll());
  }

  void _closeFullscreen() {
    final route = _fullRoute;
    final nav = _fullNavigator;
    _fullRoute = null;
    _fullNavigator = null;
    if (route?.isActive == true && nav?.mounted == true) {
      scheduleMicrotask(() {
        if (route?.isActive == true && nav?.mounted == true) {
          nav!.removeRoute(route!);
        }
      });
    }
  }

  Future<void> _release() async {
    _closeFullscreen();
    final old = _player;
    _player = null;
    _liveId = null;
    _rendered = false;
    final events = _events;
    _events = null;
    final ended = _ended;
    _ended = null;
    // Stop media without waiting for observer cancellation futures.
    unawaited(events?.cancel());
    unawaited(ended?.cancel());
    if (old != null) {
      try {
        await old.leave();
      } finally {
        old.dispose();
      }
    }
  }

  Future<void> _poll() async {
    if (!mounted || _busy || !_foreground) return;
    _timer?.cancel();
    _busy = true;
    try {
      final status = await widget.api.status(widget.orderId);
      if (!mounted || !_foreground) return;
      if (status.configured != true || status.state != 'RUNNING') {
        await _release();
        if (!mounted) return;
        setState(
          () => _message = status.configured != true
              ? '本单直播服务尚未配置'
              : status.state == 'STARTING'
              ? '飞手正在开启直播，等待实际图传首帧'
              : '飞手尚未开启本单直播，暂无画面',
        );
      } else if (_liveId != status.liveId && _failedId != status.liveId) {
        await _release();
        final credential = await widget.api.watch(
          widget.orderId,
          status.liveId!,
        );
        if (!mounted || !_foreground) return;
        if (credential.connectionId != status.connectionId) {
          throw StateError('connection changed');
        }
        final player = LivePlayerController(engine: widget.factory());
        _player = player;
        _liveId = status.liveId;
        _events = player.engine.events.listen((event) {
          if (mounted &&
              _player == player &&
              event.kind == TrtcEventKind.firstVideoFrame) {
            setState(() {
              _rendered = true;
              _message = '本单实时图传';
            });
          }
        });
        _ended = player.onEnded.listen((_) {
          if (!mounted || _player != player) return;
          _failedId = _liveId;
          unawaited(_release());
          setState(() => _message = '本单直播已中断，请重试');
        });
        await player.enter(
          LiveStreamSession(
            sdkAppId: credential.sdkAppId!,
            strRoomId: credential.roomId!,
            userId: credential.userId!,
            userSig: credential.userSig!,
            privateMapKey: credential.privateMapKey,
            publisherUserId: credential.publisherUserId,
          ),
        );
        if (!mounted || _player != player || !_foreground) {
          await player.leave();
          return;
        }
        setState(() => _message = '已连接本单直播，等待实际画面');
      }
    } catch (error) {
      await _release();
      if (mounted) {
        setState(
          () => _message = failureMessage(error, fallback: '暂时无法观看本单直播，请稍后重试'),
        );
      }
    } finally {
      _busy = false;
      if (mounted && _foreground) {
        _timer = Timer(const Duration(seconds: 5), _poll);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _failedId = null;
      unawaited(_poll());
    } else {
      _timer?.cancel();
      unawaited(_release());
    }
  }

  Widget _video(LivePlayerController player, {bool preview = false}) {
    if (!widget.useRealVideoView) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text('视频渲染视图', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return TRTCCloudVideoView(
      onViewCreated: (id) {
        if (preview) _previewId = id;
        if (_player == player) unawaited(player.attachView(id));
      },
    );
  }

  Future<void> _fullscreen() async {
    final player = _player;
    if (player == null || _fullRoute != null) return;
    final nav = Navigator.of(context);
    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('本单直播'),
            leading: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
            ),
          ),
          body: _video(player),
        ),
      ),
    );
    _fullNavigator = nav;
    _fullRoute = route;
    await nav.push(route);
    if (_fullRoute == route) {
      _fullRoute = null;
      _fullNavigator = null;
    }
    if (mounted && _player == player && _previewId != null) {
      await player.attachView(_previewId!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    void refresh() {
      _failedId = null;
      unawaited(_poll());
    }

    final video = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: const Color(0xFF1E222D),
        child: player == null
            ? SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              _failedId == null || widget.showFlightHeading
                              ? 12
                              : 46,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 6,
                          children: [
                            const Icon(
                              Icons.videocam_off_outlined,
                              size: 28,
                              color: Colors.white54,
                            ),
                            Text(
                              _message,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              '仅观看本单图传，直播由飞手控制。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_failedId != null && !widget.showFlightHeading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          tooltip: '重试连接直播',
                          onPressed: refresh,
                          icon: const Icon(Icons.replay, color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              )
            : AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _video(player, preview: true),
                    if (!_rendered)
                      const Center(
                        child: Text(
                          '等待实际画面',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Text(
                            _message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: IconButton.filled(
                        tooltip: '放大本单直播',
                        onPressed: _fullscreen,
                        icon: const Icon(Icons.fullscreen),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
    if (!widget.showFlightHeading) return video;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '实际飞行数据',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2329),
                ),
              ),
            ),
            IconButton(
              tooltip: '刷新本单直播',
              visualDensity: VisualDensity.compact,
              onPressed: refresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ],
        ),
        video,
      ],
    );
  }
}
