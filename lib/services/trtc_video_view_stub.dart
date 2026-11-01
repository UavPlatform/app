import 'package:flutter/widgets.dart';

/// Web / SKIP 路径：无真实 TRTC 视图。
class TrtcRemoteVideoView extends StatelessWidget {
  const TrtcRemoteVideoView({super.key, this.onViewCreated});

  final void Function(int viewId)? onViewCreated;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF000000),
      child: SizedBox.expand(),
    );
  }
}
