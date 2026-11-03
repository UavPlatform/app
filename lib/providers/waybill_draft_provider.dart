import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/waybill_draft_entry.dart';

import '../models/waybill_draft.dart';
import '../config/api_config.dart';
import '../services/waybill_photo_store.dart';
import 'auth_provider.dart';

final waybillPhotoStoreProvider = Provider((ref) => WaybillPhotoStore());

final waybillDraftScopeProvider = Provider<String?>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return null;
  final server = ApiConfig.resolveHttpBaseUrl(
    ref.watch(tokenStorageProvider).getServerUrl(),
  );
  return base64Url.encode(utf8.encode('$server/${user.userId}'));
});

class WaybillDraftState {
  const WaybillDraftState({
    required this.draft,
    this.entries = const [],
    this.activeId,
    this.error,
    this.saving = false,
    this.formRevision = 0,
  });
  final WaybillDraft draft;
  final List<WaybillDraftEntry> entries;
  final String? activeId, error;
  final bool saving;
  final int formRevision;
}

class WaybillDraftNotifier extends StateNotifier<WaybillDraftState> {
  WaybillDraftNotifier(this._prefs, this._key)
    : super(WaybillDraftState(draft: WaybillDraft())) {
    final raw = _key == null ? null : _prefs.getString(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final List<WaybillDraftEntry> entries;
      if (json['version'] == 2 && json['drafts'] is List) {
        entries = (json['drafts'] as List)
            .map(
              (item) => WaybillDraftEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
        if (entries.map((e) => e.id).toSet().length != entries.length) {
          throw const FormatException('草稿标识重复');
        }
      } else {
        entries = [
          WaybillDraftEntry(
            id: const Uuid().v4(),
            draft: WaybillDraft.fromJson(json),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        ];
      }
      entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _lastEdited = entries.isEmpty ? 0 : entries.first.updatedAt;
      state = WaybillDraftState(
        draft: entries.isEmpty ? WaybillDraft() : entries.first.draft,
        activeId: entries.firstOrNull?.id,
        entries: List.unmodifiable(entries),
      );
    } catch (_) {
      state = WaybillDraftState(
        draft: WaybillDraft(),
        error: '原草稿无法读取，请重新填写；原记录尚未覆盖',
      );
    }
  }

  final SharedPreferences _prefs;
  final String? _key;
  Future<void> _pending = Future.value();
  int _revision = 0, _formRevision = 0, _lastEdited = 0;

  int _touch() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastEdited = now > _lastEdited ? now : _lastEdited + 1;
    return _lastEdited;
  }

  void update(String key, String value) =>
      replace(state.draft.change(key, value));
  void move(int step) => replace(state.draft.atStep(step));

  void restore(WaybillDraft draft) {
    _formRevision++;
    replace(draft);
  }

  void replace(WaybillDraft draft) {
    final id = state.activeId ?? const Uuid().v4();
    _commit([
      WaybillDraftEntry(id: id, draft: draft, updatedAt: _touch()),
      ...state.entries.where((e) => e.id != id),
    ], id);
  }

  /// New drafts never replace another draft; switching invalidates open editors.
  Future<bool> createDraft() async {
    _formRevision++;
    final entry = WaybillDraftEntry(
      id: const Uuid().v4(),
      draft: WaybillDraft(),
      updatedAt: _touch(),
    );
    _commit([entry, ...state.entries], entry.id);
    await _pending;
    return mounted && state.error == null;
  }

  Future<bool> openDraft(String id) async {
    final entry = state.entries.where((e) => e.id == id).firstOrNull;
    if (entry == null) return false;
    _formRevision++;
    _commit([
      WaybillDraftEntry(id: id, draft: entry.draft, updatedAt: _touch()),
      ...state.entries.where((e) => e.id != id),
    ], id);
    await _pending;
    return mounted && state.error == null;
  }

  void resumeLatest() {
    if (state.entries.isEmpty || state.entries.first.id == state.activeId) {
      return;
    }
    _formRevision++;
    _commit(state.entries, state.entries.first.id);
  }

  Future<bool> deleteDraft(String id) async {
    if (!state.entries.any((e) => e.id == id)) return false;
    final previous = state;
    final entries = state.entries.where((e) => e.id != id).toList();
    if (id == state.activeId) _formRevision++;
    final active = id == state.activeId
        ? entries.firstOrNull?.id
        : state.activeId;
    _commit(entries, active);
    final revision = _revision;
    await _pending;
    if (mounted && revision == _revision && state.error != null) {
      state = WaybillDraftState(
        draft: previous.draft,
        entries: previous.entries,
        activeId: previous.activeId,
        formRevision: _formRevision,
        error: state.error,
      );
    }
    return mounted && state.error == null;
  }

  void _commit(List<WaybillDraftEntry> entries, String? activeId) {
    final revision = ++_revision;
    final active = entries.where((e) => e.id == activeId).firstOrNull;
    state = WaybillDraftState(
      draft: active?.draft ?? WaybillDraft(),
      entries: List.unmodifiable(entries),
      activeId: activeId,
      saving: true,
      formRevision: _formRevision,
    );
    // One complete snapshot is the commit unit: rapid edits cannot lose siblings.
    final payload = jsonEncode({
      'version': 2,
      'drafts': entries.map((e) => e.toJson()).toList(),
    });
    _pending = _pending.then((_) async {
      try {
        if (_key == null) throw StateError('未登录，无法保存运单');
        if (!await _prefs.setString(_key, payload)) throw StateError('写入失败');
        if (mounted && revision == _revision) _settled();
      } catch (_) {
        if (mounted && revision == _revision) _settled(error: '草稿保存失败，请重试');
      }
    });
  }

  void _settled({String? error}) {
    state = WaybillDraftState(
      draft: state.draft,
      entries: state.entries,
      activeId: state.activeId,
      formRevision: _formRevision,
      error: error,
    );
  }

  Future<bool> save() async {
    // Save the current snapshot, including an empty draft box after deletion.
    if (state.activeId == null &&
        state.entries.isEmpty &&
        state.draft.fields.isEmpty) {
      _commit([], null);
    } else {
      replace(state.draft);
    }
    await _pending;
    return mounted && state.error == null;
  }
}

final waybillDraftProvider =
    StateNotifierProvider<WaybillDraftNotifier, WaybillDraftState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      // Drafts must never cross accounts or backend environments.
      final scope = ref.watch(waybillDraftScopeProvider);
      return WaybillDraftNotifier(
        prefs,
        scope == null ? null : 'waybill.v1.$scope',
      );
    });
