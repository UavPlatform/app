import 'dart:async';

import 'dispatch_realtime_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dispatch_nearby_api.dart';
import '../api/generated/openapi_models.dart';
import '../services/dispatch_location.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final dispatchNearbyApiProvider = Provider(
  (ref) => DispatchNearbyApi(ref.watch(httpClientProvider)),
);
final dispatchLocationProvider = Provider((ref) => DispatchLocation());

class NearbyHallListState {
  const NearbyHallListState({
    this.items = const [],
    this.page = -1,
    this.hasNext = true,
    this.loading = false,
    this.error,
    this.locationState,
    this.radiusKm,
    this.locationExpiresAt,
  });

  final List<ApiDispatchNearbyOfferVO> items;
  final int page;
  final bool hasNext;
  final bool loading;
  final String? error;
  final String? locationState;
  final num? radiusKm;
  final int? locationExpiresAt;

  bool get isInitialLoading => loading && items.isEmpty && error == null;

  NearbyHallListState copyWith({
    List<ApiDispatchNearbyOfferVO>? items,
    int? page,
    bool? hasNext,
    bool? loading,
    String? error,
    bool clearError = false,
    String? locationState,
    num? radiusKm,
    int? locationExpiresAt,
    bool clearMeta = false,
  }) => NearbyHallListState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    locationState: clearMeta ? locationState : (locationState ?? this.locationState),
    radiusKm: clearMeta ? radiusKm : (radiusKm ?? this.radiusKm),
    locationExpiresAt: clearMeta
        ? locationExpiresAt
        : (locationExpiresAt ?? this.locationExpiresAt),
  );
}

class DispatchNearbyHallNotifier extends StateNotifier<NearbyHallListState> {
  DispatchNearbyHallNotifier(this._api) : super(const NearbyHallListState());
  final DispatchNearbyApi _api;

  Future<void> load({bool refresh = false}) async {
    if (state.loading || (!refresh && !state.hasNext)) return;
    final before = state;
    state = before.copyWith(loading: true, clearError: true);
    try {
      final hall = await _api.hall(refresh ? 0 : before.page + 1);
      if (!mounted) return;
      final pageItems = hall.items ?? const <ApiDispatchNearbyOfferVO>[];
      final List<ApiDispatchNearbyOfferVO> merged;
      if (refresh) {
        merged = List<ApiDispatchNearbyOfferVO>.of(pageItems);
      } else {
        final seen = <String>{
          for (final item in before.items)
            if (item.offer?.orderId != null) item.offer!.orderId!,
        };
        merged = [
          ...before.items,
          for (final item in pageItems)
            if (item.offer?.orderId != null &&
                seen.add(item.offer!.orderId!))
              item,
        ];
      }
      state = NearbyHallListState(
        items: merged,
        page: hall.page ?? (refresh ? 0 : before.page + 1),
        hasNext: hall.hasNext ?? false,
        locationState: hall.locationState,
        radiusKm: hall.radiusKm,
        locationExpiresAt: hall.locationExpiresAt,
      );
    } catch (error) {
      if (mounted) {
        state = before.copyWith(loading: false, error: '$error');
      }
    }
  }
}

final dispatchNearbyHallProvider = StateNotifierProvider.autoDispose<
  DispatchNearbyHallNotifier,
  NearbyHallListState
>((ref) {
  ref.watch(waybillDraftScopeProvider);
  final notifier = DispatchNearbyHallNotifier(
    ref.watch(dispatchNearbyApiProvider),
  );
  ref.listen<int>(dispatchRealtimeProvider, (previous, next) {
    if (previous != null && previous != next) {
      unawaited(notifier.load(refresh: true));
    }
  });
  return notifier..load();
});

final dispatchNearbyStatusProvider = FutureProvider.autoDispose
    .family<ApiDispatchNearbyStatusVO, (String, int)>((ref, key) async {
      ref.watch(waybillDraftScopeProvider);
      return dispatchSnapshot(ref, () async {
        final value = await ref.watch(dispatchNearbyApiProvider).status(key.$1);
        if (value.assignmentVersion != key.$2) {
          throw StateError('接单轮次已变化，请刷新订单');
        }
        return value;
      });
    });
