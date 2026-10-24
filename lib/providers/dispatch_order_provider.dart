import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dispatch_realtime_provider.dart';
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

final dispatchPilotHallProvider = FutureProvider.autoDispose
    .family<DispatchHall, int>((ref, page) {
      ref.watch(waybillDraftScopeProvider);
      final api = ref.watch(dispatchOrderApiProvider);
      return dispatchSnapshot(ref, () => api.pilotHall(page));
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
