import 'dispatch_realtime_provider.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/dispatch_notification_api.dart';
import '../api/generated/openapi_models.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final dispatchNotificationApiProvider = Provider(
  (ref) => DispatchNotificationApi(ref.watch(httpClientProvider)),
);
final dispatchUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  final scope = ref.watch(waybillDraftScopeProvider);
  if (scope == null) return 0;
  return dispatchSnapshot(
    ref,
    () => ref.watch(dispatchNotificationApiProvider).unread(),
  );
});

class DispatchInboxState {
  const DispatchInboxState({
    this.items = const [],
    this.readIds = const {},
    this.page = -1,
    this.hasNext = true,
    this.loading = false,
    this.error,
  });
  final List<ApiDispatchNotificationVO> items;
  final Set<String> readIds;
  final int page;
  final bool hasNext;
  final bool loading;
  final String? error;
  bool isRead(ApiDispatchNotificationVO item) =>
      item.readAt != null || readIds.contains(item.notificationId);
}

class DispatchInboxNotifier extends StateNotifier<DispatchInboxState> {
  DispatchInboxNotifier(this.api) : super(const DispatchInboxState());
  final DispatchNotificationApi api;
  bool _pendingHead = false;
  Future<void> refreshHead() async {
    if (!mounted) return;
    if (state.loading) {
      _pendingHead = true;
      return;
    }
    await load(refresh: true, preserveOlder: true);
  }

  Future<void> load({bool refresh = false, bool preserveOlder = false}) async {
    if (state.loading || (!refresh && !state.hasNext)) return;
    final before = state;
    state = DispatchInboxState(
      items: before.items,
      readIds: before.readIds,
      page: before.page,
      hasNext: before.hasNext,
      loading: true,
    );
    try {
      var next = await api.list(refresh ? 0 : before.page + 1);
      if (!mounted) return;
      final items = <String, ApiDispatchNotificationVO>{};
      if (refresh) {
        final known = before.items.map((item) => item.notificationId).toSet();
        // Catch up to the old head before merging the displayed older pages.
        // Offset pages shift on inserts, so resume from the pages just fetched.
        while (true) {
          for (final item in next.items!) {
            items[item.notificationId!] = item;
          }
          if (!preserveOlder ||
              known.isEmpty ||
              !next.hasNext! ||
              next.items!.any((item) => known.contains(item.notificationId))) {
            break;
          }
          next = await api.list(next.page! + 1);
          if (!mounted) return;
        }
      }
      if (!refresh || preserveOlder) {
        for (final item in before.items) {
          items.putIfAbsent(item.notificationId!, () => item);
        }
      }
      if (!refresh) {
        for (final item in next.items!) {
          items[item.notificationId!] = item;
        }
      }
      state = DispatchInboxState(
        items: items.values.toList(),
        readIds: state.readIds,
        page: next.page!,
        hasNext: next.hasNext!,
      );
    } catch (error) {
      if (mounted) {
        state = DispatchInboxState(
          items: before.items,
          readIds: state.readIds,
          page: before.page,
          hasNext: before.hasNext,
          error: error.toString(),
        );
      }
    } finally {
      if (_pendingHead && mounted) {
        _pendingHead = false;
        unawaited(refreshHead());
      }
    }
  }

  Future<void> read(String id) async {
    await api.read(id);
    if (!mounted) return;
    state = DispatchInboxState(
      items: state.items,
      readIds: {...state.readIds, id},
      page: state.page,
      hasNext: state.hasNext,
      loading: state.loading,
      error: state.error,
    );
  }
}

final dispatchInboxProvider =
    StateNotifierProvider.autoDispose<
      DispatchInboxNotifier,
      DispatchInboxState
    >((ref) {
      ref.watch(waybillDraftScopeProvider);
      final notifier = DispatchInboxNotifier(
        ref.watch(dispatchNotificationApiProvider),
      );
      ref.listen<int>(dispatchRealtimeProvider, (previous, next) {
        if (previous != null && previous != next) {
          unawaited(notifier.refreshHead());
        }
      });
      return notifier..load();
    });
