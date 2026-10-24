import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/waybill_draft.dart';
import '../config/api_config.dart';
import '../services/waybill_photo_store.dart';
import 'auth_provider.dart';

// Disabled until assessment, pricing and deposit contracts are connected.
final dispatchWaybillEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('DISPATCH_WAYBILL_ENABLED'),
);

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
    this.error,
    this.saving = false,
    this.formRevision = 0,
  });
  final WaybillDraft draft;
  final String? error;
  final bool saving;
  final int formRevision;
}

class WaybillDraftNotifier extends StateNotifier<WaybillDraftState> {
  WaybillDraftNotifier(this._prefs, this._key)
    : super(WaybillDraftState(draft: WaybillDraft())) {
    final raw = _key == null ? null : _prefs.getString(_key);
    if (raw != null) {
      try {
        state = WaybillDraftState(
          draft: WaybillDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        state = WaybillDraftState(
          draft: WaybillDraft(),
          error: '原草稿无法读取，请重新填写；原记录尚未覆盖',
        );
      }
    }
  }

  final SharedPreferences _prefs;
  final String? _key;
  Future<void> _pending = Future.value();
  int _revision = 0;
  int _formRevision = 0;

  void update(String key, String value) =>
      replace(state.draft.change(key, value));

  void move(int step) => replace(state.draft.atStep(step));

  void restore(WaybillDraft draft) {
    _formRevision++;
    replace(draft);
  }

  void replace(WaybillDraft draft) {
    final revision = ++_revision;
    state = WaybillDraftState(
      draft: draft,
      saving: true,
      formRevision: _formRevision,
    );
    final payload = jsonEncode(draft.toJson());
    _pending = _pending.then((_) async {
      try {
        if (_key == null) throw StateError('未登录，无法保存运单');
        if (!await _prefs.setString(_key, payload)) {
          throw StateError('写入失败');
        }
        if (mounted && revision == _revision) {
          state = WaybillDraftState(
            draft: state.draft,
            formRevision: _formRevision,
          );
        }
      } catch (_) {
        if (mounted && revision == _revision) {
          state = WaybillDraftState(
            draft: state.draft,
            error: '草稿保存失败，请重试',
            formRevision: _formRevision,
          );
        }
      }
    });
  }

  Future<bool> save() async {
    replace(state.draft);
    await _pending;
    return mounted && state.error == null;
  }
}

final waybillDraftProvider =
    StateNotifierProvider.autoDispose<WaybillDraftNotifier, WaybillDraftState>((
      ref,
    ) {
      final prefs = ref.watch(sharedPreferencesProvider);
      // Drafts must never cross accounts or backend environments.
      final scope = ref.watch(waybillDraftScopeProvider);
      return WaybillDraftNotifier(
        prefs,
        scope == null ? null : 'waybill.v1.$scope',
      );
    });
