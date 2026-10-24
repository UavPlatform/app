import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dispatch_material_api.dart';
import '../services/attachment_file_source.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final dispatchMaterialApiProvider = Provider((ref) {
  ref.watch(waybillDraftScopeProvider);
  final api = DispatchMaterialApi(ref.watch(httpClientProvider));
  ref.onDispose(api.dispose);
  return api;
});
final dispatchMaterialSourceProvider = Provider(
  (ref) => ImagePickerAttachmentSource(),
);
final dispatchMaterialsProvider = FutureProvider.autoDispose
    .family<List<DispatchMaterial>, String>((ref, id) {
      ref.watch(waybillDraftScopeProvider);
      return ref.watch(dispatchMaterialApiProvider).list(id);
    });
