import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('rapid updates and step changes persist the newest snapshot', () async {
    final notifier = WaybillDraftNotifier(prefs, 'account-a/server-a');
    for (var i = 1; i <= 20; i++) {
      notifier.update('weightMin', '$i');
    }
    notifier.move(2);
    expect(await notifier.save(), isTrue);
    final restored = WaybillDraftNotifier(prefs, 'account-a/server-a');
    expect(restored.state.draft.value('weightMin'), '20');
    expect(restored.state.draft.step, 2);
    notifier.dispose();
    restored.dispose();
  });

  test('different account or server never restores another draft', () async {
    final a = WaybillDraftNotifier(prefs, 'account-a/server-a');
    a.update('start.contact', 'account A only');
    await a.save();
    for (final key in ['account-b/server-a', 'account-a/server-b']) {
      final other = WaybillDraftNotifier(prefs, key);
      expect(other.state.draft.fields, isEmpty);
      other.dispose();
    }
    a.dispose();
  });

  test('anonymous draft reports save failure and never persists', () async {
    final notifier = WaybillDraftNotifier(prefs, null);
    notifier.update('start.contact', 'private');
    expect(await notifier.save(), isFalse);
    expect(prefs.getKeys(), isEmpty);
    notifier.dispose();
  });

  test(
    'corrupt draft remains untouched until the user edits or saves',
    () async {
      await prefs.setString('account-a', '{broken');
      final notifier = WaybillDraftNotifier(prefs, 'account-a');
      expect(notifier.state.error, contains('无法读取'));
      expect(prefs.getString('account-a'), '{broken');
      notifier.dispose();
    },
  );

  test(
    'queued writes survive page disposal without writing into another scope',
    () async {
      final first = WaybillDraftNotifier(prefs, 'account-a');
      first.update('start.contact', 'A');
      final pending = first.save();
      first.dispose();
      final second = WaybillDraftNotifier(prefs, 'account-b');
      second.update('start.contact', 'B');
      await second.save();
      await pending;
      final restored = WaybillDraftNotifier(prefs, 'account-a');
      expect(restored.state.draft.value('start.contact'), 'A');
      expect(second.state.draft.value('start.contact'), 'B');
      restored.dispose();
      second.dispose();
    },
  );
}
