import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uav_pilot_app/providers/dispatch_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../dispatch_test_support.dart';

void main() {
  late FakeDispatchApi api;
  late AccountDraftNotifier notifier;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final client = HttpClient(
      TokenStorage(await SharedPreferences.getInstance()),
    );
    api = FakeDispatchApi(client);
    notifier = AccountDraftNotifier(api);
    addTearDown(notifier.dispose);
    addTearDown(() => client.dio.close());
  });

  test(
    'load does not write; existing draft needs explicit replacement',
    () async {
      api.remote = AccountWaybillDraft(draft: WaybillDraft(), revision: 4);
      await notifier.load();
      expect(api.saveCalls, 0);
      expect(await notifier.save(WaybillDraft()), isFalse);
      expect(api.saveCalls, 0);
      expect(
        await notifier.save(WaybillDraft(), replaceExisting: true),
        isTrue,
      );
      expect(api.sentRevision, 4);
      expect(notifier.state.draft!.revision, 5);
    },
  );

  test('failed initial load blocks writes without a known revision', () async {
    api.loadError = const DispatchApiException('offline');
    expect(await notifier.load(), isFalse);
    expect(await notifier.save(WaybillDraft()), isFalse);
    expect(api.saveCalls, 0);
  });

  test(
    'conflict requires fresh load and does not retry automatically',
    () async {
      await notifier.load();
      api.saveError = const DispatchApiException(
        'updated elsewhere',
        code: 'WAYBILL_DRAFT_CONFLICT',
      );
      expect(await notifier.save(WaybillDraft()), isFalse);
      expect(notifier.state.conflict, isTrue);
      expect(await notifier.save(WaybillDraft()), isFalse);
      expect(api.saveCalls, 1);
      api.saveError = null;
      await notifier.load();
      expect(await notifier.save(WaybillDraft()), isTrue);
    },
  );
}
