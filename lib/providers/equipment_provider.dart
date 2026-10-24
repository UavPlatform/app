import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/equipment_api.dart';
import '../api/generated/openapi_models.dart';
import '../services/equipment_request_store.dart';
import 'auth_provider.dart';
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
final equipmentBorrowsProvider = FutureProvider.autoDispose
    .family<ApiDroneBorrowPageVO, int>((ref, page) {
      ref.watch(waybillDraftScopeProvider);
      return ref.watch(equipmentApiProvider).mine(page);
    });
