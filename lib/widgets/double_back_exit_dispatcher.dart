import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Let dialogs and child routes pop first; confirm only an Android root exit.
class DoubleBackExitDispatcher extends RootBackButtonDispatcher {
  DoubleBackExitDispatcher({
    required this.showPrompt,
    Future<void> Function()? onExit,
    this.interval = const Duration(seconds: 2),
  }) : _onExit = onExit ?? (() => SystemNavigator.pop());

  final VoidCallback showPrompt;
  final Future<void> Function() _onExit;
  final Duration interval;
  Timer? _window;
  bool _handling = false;
  bool _closed = false;

  void reset() {
    _window?.cancel();
    _window = null;
  }

  void close() {
    _closed = true;
    reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) reset();
  }

  @override
  Future<bool> didPopRoute() async {
    if (_closed || _handling) return true;
    _handling = true;
    try {
      if (await super.didPopRoute()) {
        reset();
        return true;
      }
      if (_closed) return true;
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        return false;
      }
      if (_window?.isActive == true) {
        reset();
        await _onExit();
        return true;
      }
      _window = Timer(interval, reset);
      showPrompt();
      return true;
    } finally {
      _handling = false;
    }
  }
}
