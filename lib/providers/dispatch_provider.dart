import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dispatch_api.dart';
import '../models/waybill_draft.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final dispatchApiProvider = Provider(
  (ref) => DispatchApi(ref.watch(httpClientProvider)),
);
final dispatchSettingsProvider = FutureProvider.autoDispose<DispatchSettings>((
  ref,
) {
  ref.watch(waybillDraftScopeProvider);
  return ref.watch(dispatchApiProvider).settings();
});

class AccountDraftState {
  const AccountDraftState({
    this.draft,
    this.loaded = false,
    this.busy = false,
    this.error,
    this.conflict = false,
  });
  final AccountWaybillDraft? draft;
  final bool loaded;
  final bool busy;
  final String? error;
  final bool conflict;
}

class AccountDraftNotifier extends StateNotifier<AccountDraftState> {
  AccountDraftNotifier(this._api) : super(const AccountDraftState());
  final DispatchApi _api;

  Future<bool> load() async {
    if (state.busy) return false;
    state = AccountDraftState(draft: state.draft, busy: true);
    try {
      final result = await _api.loadDraft();
      if (!mounted) return false;
      state = AccountDraftState(draft: result, loaded: true);
      return true;
    } catch (error) {
      if (mounted) {
        state = AccountDraftState(
          draft: state.draft,
          error: error is DispatchApiException
              ? error.message
              : '账号草稿暂时无法读取，请重试',
        );
      }
      return false;
    }
  }

  Future<bool> save(WaybillDraft draft, {bool replaceExisting = false}) async {
    if (state.busy || !state.loaded || state.conflict) return false;
    if (state.draft != null && !replaceExisting) {
      state = AccountDraftState(
        draft: state.draft,
        loaded: true,
        error: '账号已有草稿，请先恢复或确认更新',
      );
      return false;
    }
    final previous = state.draft;
    state = AccountDraftState(draft: previous, loaded: true, busy: true);
    try {
      final result = await _api.saveDraft(draft, previous?.revision);
      if (!mounted) return false;
      state = AccountDraftState(draft: result, loaded: true);
      return true;
    } catch (error) {
      if (mounted) {
        state = AccountDraftState(
          draft: previous,
          loaded: true,
          error: error is DispatchApiException
              ? error.message
              : '账号草稿暂时无法保存，请重试',
          conflict:
              error is DispatchApiException &&
              error.code == 'WAYBILL_DRAFT_CONFLICT',
        );
      }
      return false;
    }
  }
}

final accountDraftProvider =
    StateNotifierProvider.autoDispose<AccountDraftNotifier, AccountDraftState>((
      ref,
    ) {
      ref.watch(waybillDraftScopeProvider);
      return AccountDraftNotifier(ref.watch(dispatchApiProvider));
    });
