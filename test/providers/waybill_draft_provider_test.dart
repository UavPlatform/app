import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/providers/waybill_draft_provider.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';

class _WritablePreferences implements SharedPreferences {
  _WritablePreferences(this.delegate);
  final SharedPreferences delegate;
  bool failWrites = false;
  @override
  String? getString(String key) => delegate.getString(key);
  @override
  Future<bool> setString(String key, String value) async =>
      failWrites ? false : delegate.setString(key, value);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('failed deletion keeps the record visible and can be retried', () async {
    final storage = _WritablePreferences(prefs);
    final notifier = WaybillDraftNotifier(storage, 'failed-delete');
    notifier.update('category', '普通');
    await notifier.save();
    final id = notifier.state.activeId!;
    storage.failWrites = true;
    expect(await notifier.deleteDraft(id), isFalse);
    expect(notifier.state.entries.single.id, id);
    expect(notifier.state.draft.value('category'), '普通');
    storage.failWrites = false;
    expect(await notifier.deleteDraft(id), isTrue);
    final restored = WaybillDraftNotifier(prefs, 'failed-delete');
    expect(restored.state.entries, isEmpty);
    notifier.dispose();
    restored.dispose();
  });

  test(
    'legacy draft migrates without losing photos or submission markers',
    () async {
      final legacy = jsonEncode(
        WaybillDraft(
          fields: {
            'category': '普通',
            'cargo.photo.a': '/local/photo.jpg',
            'submission.requestKey': 'attempt-a',
          },
          step: 3,
        ).toJson(),
      );
      await prefs.setString('legacy', legacy);
      final notifier = WaybillDraftNotifier(prefs, 'legacy');
      expect(notifier.state.entries.length, 1);
      expect(prefs.getString('legacy'), legacy);
      final id = notifier.state.activeId;
      expect(await notifier.save(), isTrue);
      expect(jsonDecode(prefs.getString('legacy')!)['version'], 2);
      final restored = WaybillDraftNotifier(prefs, 'legacy');
      expect(restored.state.activeId, id);
      expect(restored.state.draft.value('cargo.photo.a'), '/local/photo.jpg');
      expect(restored.state.draft.value('submission.requestKey'), 'attempt-a');
      expect(restored.state.draft.step, 3);
      notifier.dispose();
      restored.dispose();
    },
  );

  test(
    'multiple drafts remain independent and reopening defaults to the last edited',
    () async {
      final notifier = WaybillDraftNotifier(prefs, 'multi');
      notifier.update('start.site', '第一份');
      notifier.update('submission.requestKey', 'attempt-first');
      final first = notifier.state.activeId!;
      expect(await notifier.createDraft(), isTrue);
      final second = notifier.state.activeId!;
      expect(second, isNot(first));
      expect(notifier.state.draft.fields, isEmpty);
      notifier.update('start.site', '第二份');
      expect(await notifier.openDraft(first), isTrue);
      notifier.update('category', '易碎');
      await notifier.save();
      final restored = WaybillDraftNotifier(prefs, 'multi');
      expect(restored.state.activeId, first);
      expect(restored.state.entries.length, 2);
      expect(
        restored.state.draft.value('submission.requestKey'),
        'attempt-first',
      );
      final untouched = restored.state.entries.singleWhere(
        (e) => e.id == second,
      );
      expect(untouched.draft.value('start.site'), '第二份');
      expect(untouched.draft.value('category'), isEmpty);
      expect(untouched.draft.value('submission.requestKey'), isEmpty);
      expect(
        restored.state.entries.first.updatedAt,
        greaterThan(untouched.updatedAt),
      );
      notifier.dispose();
      restored.dispose();
    },
  );

  test(
    'deleting active and final drafts retains siblings and never resurrects records',
    () async {
      final notifier = WaybillDraftNotifier(prefs, 'delete');
      notifier.update('category', '普通');
      final first = notifier.state.activeId!;
      await notifier.createDraft();
      final second = notifier.state.activeId!;
      final revision = notifier.state.formRevision;
      expect(await notifier.deleteDraft(second), isTrue);
      expect(notifier.state.activeId, first);
      expect(notifier.state.draft.value('category'), '普通');
      expect(notifier.state.formRevision, greaterThan(revision));
      expect(await notifier.deleteDraft(first), isTrue);
      await notifier.save();
      final restored = WaybillDraftNotifier(prefs, 'delete');
      expect(restored.state.entries, isEmpty);
      expect(restored.state.activeId, isNull);
      expect(restored.state.draft.fields, isEmpty);
      notifier.dispose();
      restored.dispose();
    },
  );

  test(
    'rapid draft switches persist one coherent box across disposal',
    () async {
      final notifier = WaybillDraftNotifier(prefs, 'queued');
      notifier.update('category', '普通');
      final first = notifier.state.activeId!;
      await notifier.createDraft();
      notifier.update('category', '易碎');
      final pending = notifier.openDraft(first);
      notifier.dispose();
      await pending;
      final restored = WaybillDraftNotifier(prefs, 'queued');
      expect(restored.state.entries.length, 2);
      expect(restored.state.activeId, first);
      expect(restored.state.draft.value('category'), '普通');
      restored.dispose();
    },
  );

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
