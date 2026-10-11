// 直播观看页（t38）：进房用 /live/get 凭证（userId/userSig 用响应值，不自报身份），
// strRoomId 字符串房间；用户退出仅释放播放资源，不调用 /live/close
//（那是「结束观看=停止推流」的停止链路，仅运营端使用，t12）。
// 直播结束（远端停流/onExitRoom）时正确退出并释放资源（t38⑤）。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';

import '../../api/live_api.dart';
import '../../providers/auth_provider.dart';
import '../../services/live_player.dart';
import '../../theme/app_colors.dart';

class LiveWatchPage extends ConsumerStatefulWidget {
  final String deviceId;
  final String? orderNum;

  /// 测试置 false：不创建平台视频视图（改用占位），其余逻辑一致
  final bool useRealVideoView;

  const LiveWatchPage({
    super.key,
    required this.deviceId,
    this.orderNum,
    this.useRealVideoView = true,
  });

  @override
  ConsumerState<LiveWatchPage> createState() => _LiveWatchPageState();
}

class _LiveWatchPageState extends ConsumerState<LiveWatchPage> {
  LiveApi? _api;
  LivePlayerController? _controller;
  bool _loading = true;
  String? _error;
  bool _ended = false;
  bool _leaving = false;
  bool _leaveSent = false;
  bool _watchStarted = false;
  StreamSubscription<void>? _endedSub;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// 缓存 API 实例：dispose 阶段不可再读 ref
  LiveApi get _liveApi => _api ??= LiveApi(ref.read(httpClientProvider));

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
      _ended = false;
    });
    final api = _liveApi;
    try {
      final result = await api.pullCredentials(widget.deviceId);
      if (!mounted) return;
      if (!result.success || result.data == null) {
        setState(() {
          _error = result.message ?? '获取直播凭证失败';
          _loading = false;
        });
        return;
      }
      final credential = result.data!;
      if (!credential.isRunning) {
        setState(() {
          _error = '直播当前未在运行';
          _loading = false;
        });
        return;
      }
      final controller = LivePlayerController(engine: ref.watch(liveEngineProvider));
      _controller = controller;
      _watchStarted = true;
      _endedSub?.cancel();
      _endedSub = controller.onEnded.listen((_) {
        if (!mounted) return;
        // 直播结束（主播停流/房间解散）：展示结束态并释放资源
        _releasePlayer();
        setState(() => _ended = true);
      });
      await controller.enter(
        LiveStreamSession(
          sdkAppId: credential.sdkAppId,
          strRoomId: credential.roomId,
          userId: credential.userId,
          userSig: credential.userSig,
        ),
      );
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      _releasePlayer();
      setState(() {
        _error = '进入直播间失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<void> _releasePlayer() async {
    if (_leaving) return;
    _leaving = true;
    await _controller?.leave();
    _leaving = false;
    // t38④：结束本用户观看记录（不动推流，幂等，失败由 LIVE_STOPPED 兜底）
    _sendLeave();
  }

  /// 结束观看记录（幂等，仅发送一次）
  void _sendLeave() {
    if (_leaveSent) return;
    _leaveSent = true;
    unawaited(_liveApi.leaveLive(widget.deviceId));
  }

  Future<void> _close() async {
    await _releasePlayer();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _endedSub?.cancel();
    // 退出页面即释放播放资源并补观看记录（不调 /live/close，不误停推流）
    unawaited(_controller?.leave());
    if (_watchStarted) _sendLeave();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('观看直播'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _ended
                  ? _buildEnded()
                  : _buildLive(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(onPressed: _start, child: const Text('重试')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _close, child: const Text('返回')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnded() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 72,
            color: AppColors.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text('直播已结束', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: _close, child: const Text('知道了')),
        ],
      ),
    );
  }

  Widget _buildLive() {
    final controller = _controller!;
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: widget.useRealVideoView
                ? TRTCCloudVideoView(
                    onViewCreated: (viewId) {
                      controller.attachView(viewId);
                    },
                  )
                : const SizedBox.expand(
                    key: Key('live-video-placeholder'),
                  ),
          ),
        ),
        const ListTile(
          leading: Icon(Icons.live_tv, color: AppColors.error),
          title: Text('作业直播进行中', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('画面来自作业现场无人机（实时）'),
        ),
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '提示：观看期间请保持网络畅通；退出本页不会中断飞手的直播推流。',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
