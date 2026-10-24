import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';

class FakeDispatchApi extends DispatchApi {
  FakeDispatchApi(super.client);
  AccountWaybillDraft? remote;
  Object? loadError;
  Object? saveError;
  int saveCalls = 0;
  int? sentRevision;

  @override
  Future<AccountWaybillDraft?> loadDraft() async {
    if (loadError != null) throw loadError!;
    return remote;
  }

  @override
  Future<AccountWaybillDraft> saveDraft(
    WaybillDraft draft,
    int? revision,
  ) async {
    saveCalls++;
    sentRevision = revision;
    if (saveError != null) throw saveError!;
    return remote = AccountWaybillDraft(
      draft: WaybillDraft(fields: draft.cloudFields, step: draft.step),
      revision: (revision ?? -1) + 1,
    );
  }
}
