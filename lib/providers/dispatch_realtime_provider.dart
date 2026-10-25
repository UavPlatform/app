import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dispatch_realtime.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final dispatchEventSourceProvider = Provider<DispatchEventSource>(
  (ref) => DioDispatchEventSource(ref.watch(httpClientProvider)),
);

/// One connection shared by all active order providers in this account/server.
final dispatchRealtimeProvider =
    StateNotifierProvider.autoDispose<DispatchRealtimeNotifier, int>((ref) {
      final scope = ref.watch(waybillDraftScopeProvider);
      return DispatchRealtimeNotifier(
        scope == null ? null : ref.watch(dispatchEventSourceProvider),
      );
    });

Future<T> dispatchSnapshot<T>(Ref ref, Future<T> Function() load) {
  var loading = true;
  var pending = false;
  var disposed = false;
  ref.onDispose(() => disposed = true);
  ref.listen<int>(dispatchRealtimeProvider, (previous, next) {
    if (previous == null || previous == next) return;
    if (loading) {
      pending = true;
    } else {
      ref.invalidateSelf();
    }
  });
  return load().whenComplete(() {
    loading = false;
    if (pending && !disposed) ref.invalidateSelf();
  });
}

class DispatchRealtimeNotifier extends StateNotifier<int>
    with WidgetsBindingObserver {
  DispatchRealtimeNotifier(this.source) : super(0) {
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    if (source != null && _foreground) _connect();
  }
  final DispatchEventSource? source;
  StreamSubscription<String>? _subscription;
  CancelToken? _cancel;
  Timer? _retry, _fallback, _batch;
  bool _foreground = false;
  int _epoch = 0, _attempts = 0;
  final _random = Random();

  bool _current(int epoch) => mounted && _foreground && epoch == _epoch;
  void _connect() {
    if (!mounted || !_foreground || source == null) return;
    final epoch = ++_epoch;
    _cancel = CancelToken();
    _fallback ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => _notify(epoch),
    );
    try {
      _subscription = source!
          .connect(_cancel!)
          .listen(
            (event) {
              if (!_current(epoch)) return;
              _attempts = 0;
              _fallback?.cancel();
              _fallback = null;
              if (event != 'heartbeat') _notify(epoch);
            },
            onError: (Object error) => _reconnect(epoch),
            onDone: () => _reconnect(epoch),
            cancelOnError: true,
          );
    } catch (_) {
      _reconnect(epoch);
    }
  }

  void _notify(int epoch) {
    if (!_current(epoch) || _batch != null) return;
    _batch = Timer(const Duration(milliseconds: 180), () {
      _batch = null;
      if (_current(epoch)) state++;
    });
  }

  void _reconnect(int epoch) {
    if (!_current(epoch) || _retry != null) return;
    _cancel?.cancel('Reconnect');
    unawaited(_release(_subscription));
    _fallback?.cancel();
    _fallback = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _notify(_epoch),
    );
    _attempts = min(_attempts + 1, 6);
    final seconds = min(1 << (_attempts - 1), 30);
    _retry = Timer(
      Duration(milliseconds: seconds * 1000 + _random.nextInt(250)),
      () {
        _retry = null;
        if (_current(epoch)) _connect();
      },
    );
  }

  Future<void> _release(StreamSubscription<String>? subscription) async {
    try {
      await subscription?.cancel();
    } catch (error, stack) {
      if (error is DioException && CancelToken.isCancel(error)) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'dispatch SSE cleanup',
        ),
      );
    }
  }

  void _stop() {
    _epoch++;
    _cancel?.cancel('Inactive');
    _cancel = null;
    unawaited(_release(_subscription));
    _subscription = null;
    _retry?.cancel();
    _retry = null;
    _fallback?.cancel();
    _fallback = null;
    _batch?.cancel();
    _batch = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active == _foreground) return;
    _foreground = active;
    if (!active) {
      _stop();
    } else if (source != null) {
      this.state++;
      _connect();
    }
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
