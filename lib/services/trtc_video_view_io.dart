import 'package:flutter/widgets.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_video_view.dart';

import 'trtc_engine_factory.dart';
import 'trtc_video_view_stub.dart' as stub;

/// IO 平台：受支持且未 SKIP 时用官方视图，否则占位。
class TrtcRemoteVideoView extends StatelessWidget {
  const TrtcRemoteVideoView({super.key, this.onViewCreated});

  final void Function(int viewId)? onViewCreated;

  @override
  Widget build(BuildContext context) {
    if (!useRealTrtcVideoView) {
      return stub.TrtcRemoteVideoView(onViewCreated: onViewCreated);
    }
    return TRTCCloudVideoView(onViewCreated: onViewCreated);
  }
}
