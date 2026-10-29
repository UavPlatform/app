import 'dart:io' show Platform;

import 'live_player.dart';
import 'live_player_trtc.dart' as trtc;

const bool skipTrtc = bool.fromEnvironment('SKIP_TRTC', defaultValue: false);

TrtcEngine createTrtcEngine() {
  if (skipTrtc || !_trtcNativeSupported) {
    return StubTrtcEngine();
  }
  return trtc.TrtcEngineImpl();
}

bool get _trtcNativeSupported {
  return Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isWindows ||
      Platform.isMacOS;
}

bool get useRealTrtcVideoView => !skipTrtc && _trtcNativeSupported;
