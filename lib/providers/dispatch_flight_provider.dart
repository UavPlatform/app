import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dispatch_flight_api.dart';
import '../api/dispatch_api.dart';
import '../api/generated/openapi_models.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final dispatchFlightApiProvider = Provider(
  (ref) => DispatchFlightApi(ref.watch(httpClientProvider)),
);

class DispatchFlightState {
  const DispatchFlightState({
    this.current,
    this.samples = const [],
    this.error,
  });
  final ApiFlightViewVO? current;
  final List<ApiFlightSampleVO> samples;
  final String? error;
}

class DispatchFlightNotifier extends StateNotifier<DispatchFlightState> {
  DispatchFlightNotifier(this.api, this.id)
    : super(const DispatchFlightState());
  final DispatchFlightApi api;
  final String id;
  Timer? _timer;
  bool _busy = false;
  int _after = 0;
  Future<void> refresh() async {
    if (!mounted || _busy) return;
    _timer?.cancel();
    _busy = true;
    try {
      final current = await api.current(id);
      if (!mounted) return;
      final points = {for (final p in state.samples) p.sampleId!: p};
      var cursor = _after;
      while (mounted) {
        final page = await api.track(id, cursor);
        if (!mounted) return;
        for (final p in page.items!) {
          points[p.sampleId!] = p;
        }
        cursor = page.nextAfter!;
        if (!page.hasNext!) break;
      }
      if (!mounted) return;
      _after = cursor;
      state = DispatchFlightState(
        current: current,
        samples: points.values.toList(),
      );
    } catch (error) {
      if (mounted) {
        final denied =
            error is DispatchApiException &&
            {
              'ORDER_NOT_FOUND',
              'NO_PERMISSION',
              'UNAUTHORIZED',
            }.contains(error.code);
        if (denied) _after = 0;
        state = DispatchFlightState(
          current: denied ? null : state.current,
          samples: denied ? const [] : state.samples,
          error: denied ? '本单飞行数据已不可读取，请返回订单列表刷新' : '飞行数据暂时无法更新，以下为上次收到的数据',
        );
      }
    } finally {
      _busy = false;
      if (mounted) _timer = Timer(const Duration(seconds: 5), refresh);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final dispatchFlightProvider = StateNotifierProvider.autoDispose
    .family<DispatchFlightNotifier, DispatchFlightState, String>((ref, id) {
      final scope = ref.watch(waybillDraftScopeProvider);
      final notifier = DispatchFlightNotifier(
        ref.watch(dispatchFlightApiProvider),
        id,
      );
      if (scope != null) unawaited(notifier.refresh());
      return notifier;
    });
