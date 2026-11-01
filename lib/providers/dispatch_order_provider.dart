import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dispatch_realtime_provider.dart';
import 'paged_list.dart';
import '../api/dispatch_order_api.dart';
import '../models/dispatch_order.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final dispatchOrderApiProvider = Provider(
  (ref) => DispatchOrderApi(ref.watch(httpClientProvider)),
);

final dispatchOrdersProvider = FutureProvider.autoDispose<List<DispatchOrder>>((
  ref,
) {
  ref.watch(waybillDraftScopeProvider);
  return dispatchSnapshot(
    ref,
    () => ref.watch(dispatchOrderApiProvider).list(),
  );
});
final dispatchOrderProvider = FutureProvider.autoDispose
    .family<DispatchOrder, String>((ref, id) {
      ref.watch(waybillDraftScopeProvider);
      final api = ref.watch(dispatchOrderApiProvider);
      return dispatchSnapshot(ref, () => api.get(id));
    });

class DispatchPilotHallNotifier extends OffsetPagedNotifier<DispatchOffer> {
  DispatchPilotHallNotifier(this._api) : super();
  final DispatchOrderApi _api;

  @override
  String itemKey(DispatchOffer item) => item.id;

  @override
  Future<OffsetPage<DispatchOffer>> fetchPage(int page) async {
    final hall = await _api.pilotHall(page);
    return (items: hall.items, page: hall.page, hasNext: hall.hasNext);
  }
}

final dispatchPilotHallProvider = StateNotifierProvider.autoDispose<
  DispatchPilotHallNotifier,
  PagedListState<DispatchOffer>
>((ref) {
  ref.watch(waybillDraftScopeProvider);
  final notifier = DispatchPilotHallNotifier(
    ref.watch(dispatchOrderApiProvider),
  );
  ref.listen<int>(dispatchRealtimeProvider, (previous, next) {
    if (previous != null && previous != next) {
      unawaited(notifier.load(refresh: true));
    }
  });
  return notifier..load();
});

final dispatchPilotOrdersProvider =
    FutureProvider.autoDispose<List<DispatchOrder>>((ref) {
      ref.watch(waybillDraftScopeProvider);
      final api = ref.watch(dispatchOrderApiProvider);
      return dispatchSnapshot(ref, () => api.pilotOrders());
    });
final dispatchPilotOrderProvider = FutureProvider.autoDispose
    .family<DispatchOrder, String>((ref, id) {
      ref.watch(waybillDraftScopeProvider);
      final api = ref.watch(dispatchOrderApiProvider);
      return dispatchSnapshot(ref, () => api.pilotGet(id));
    });
