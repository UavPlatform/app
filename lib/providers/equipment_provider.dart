import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/equipment_api.dart';
import '../api/generated/openapi_models.dart';
import '../services/equipment_request_store.dart';
import 'auth_provider.dart';
import 'paged_list.dart';
import 'waybill_draft_provider.dart';

final equipmentApiProvider = Provider(
  (ref) => EquipmentApi(ref.watch(httpClientProvider)),
);
final equipmentRequestStoreProvider = Provider(
  (ref) => EquipmentRequestStore(ref.watch(sharedPreferencesProvider)),
);
final equipmentCatalogProvider = FutureProvider.autoDispose
    .family<ApiProviderDronePageVO, int>((ref, page) {
      ref.watch(waybillDraftScopeProvider);
      return ref.watch(equipmentApiProvider).catalog(page);
    });
final equipmentModelStockProvider =
    FutureProvider.autoDispose<ApiModelStockVO>((ref) {
      ref.watch(waybillDraftScopeProvider);
      return ref.watch(equipmentApiProvider).modelStock();
    });

class EquipmentBorrowsNotifier extends OffsetPagedNotifier<ApiDroneBorrowVO> {
  EquipmentBorrowsNotifier(this._api) : super();
  final EquipmentApi _api;

  @override
  String itemKey(ApiDroneBorrowVO item) => item.borrowId ?? '${item.hashCode}';

  @override
  Future<OffsetPage<ApiDroneBorrowVO>> fetchPage(int page) async {
    final result = await _api.mine(page);
    return (
      items: result.items ?? const <ApiDroneBorrowVO>[],
      page: result.page ?? page,
      hasNext: result.hasNext ?? false,
    );
  }
}

final equipmentBorrowsProvider = StateNotifierProvider.autoDispose<
  EquipmentBorrowsNotifier,
  PagedListState<ApiDroneBorrowVO>
>((ref) {
  ref.watch(waybillDraftScopeProvider);
  return EquipmentBorrowsNotifier(ref.watch(equipmentApiProvider))..load();
});

final equipmentCurrentProvider =
    FutureProvider.autoDispose<ApiDroneBorrowPageVO>((ref) {
      ref.watch(waybillDraftScopeProvider);
      return ref.watch(equipmentApiProvider).current();
    });
