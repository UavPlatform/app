import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared paging snapshot for offset / page-index lists.
class PagedListState<T> {
  const PagedListState({
    this.items = const [],
    this.page = -1,
    this.hasNext = true,
    this.loading = false,
    this.error,
  });

  final List<T> items;
  final int page;
  final bool hasNext;
  final bool loading;
  final String? error;

  bool get isInitialLoading => loading && items.isEmpty && error == null;

  PagedListState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasNext,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => PagedListState<T>(
    items: items ?? this.items,
    page: page ?? this.page,
    hasNext: hasNext ?? this.hasNext,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

typedef OffsetPage<T> = ({List<T> items, int page, bool hasNext});

/// Offset page loader: refresh replaces; append dedupes by [itemKey].
///
/// A [load] with `refresh: true` that arrives while another load is in flight
/// is queued (`_pendingHead`) and run after the current load finishes —
/// same idea as [DispatchInboxNotifier._pendingHead].
abstract class OffsetPagedNotifier<T> extends StateNotifier<PagedListState<T>> {
  OffsetPagedNotifier() : super(PagedListState<T>());

  bool _pendingHead = false;

  String itemKey(T item);

  Future<OffsetPage<T>> fetchPage(int page);

  Future<void> load({bool refresh = false}) async {
    if (state.loading) {
      if (refresh) _pendingHead = true;
      return;
    }
    if (!refresh && !state.hasNext) return;
    final before = state;
    state = before.copyWith(loading: true, clearError: true);
    try {
      final next = await fetchPage(refresh ? 0 : before.page + 1);
      if (!mounted) return;
      final List<T> merged;
      if (refresh) {
        merged = List<T>.of(next.items);
      } else {
        final seen = before.items.map(itemKey).toSet();
        merged = [
          ...before.items,
          for (final item in next.items)
            if (seen.add(itemKey(item))) item,
        ];
      }
      state = PagedListState<T>(
        items: merged,
        page: next.page,
        hasNext: next.hasNext,
      );
    } catch (error) {
      if (mounted) {
        state = before.copyWith(loading: false, error: '$error');
      }
    } finally {
      if (_pendingHead && mounted) {
        _pendingHead = false;
        unawaited(load(refresh: true));
      }
    }
  }
}
