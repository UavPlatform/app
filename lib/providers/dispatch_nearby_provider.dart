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
final dispatchNearbyHallProvider = FutureProvider.autoDispose
    .family<ApiDispatchNearbyHallVO, int>((ref, page) {
      ref.watch(waybillDraftScopeProvider);
      return dispatchSnapshot(
        ref,
        () => ref.watch(dispatchNearbyApiProvider).hall(page),
      );
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
