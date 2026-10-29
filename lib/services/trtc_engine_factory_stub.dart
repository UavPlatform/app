import 'live_player.dart';

const bool skipTrtc = bool.fromEnvironment('SKIP_TRTC', defaultValue: false);

TrtcEngine createTrtcEngine() => StubTrtcEngine();

bool get useRealTrtcVideoView => false;
