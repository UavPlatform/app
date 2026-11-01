import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/providers/paged_list.dart';

class _Item {
  const _Item(this.id);
  final String id;
}

class _FakeNotifier extends OffsetPagedNotifier<_Item> {
  _FakeNotifier(this.pages);
  final Map<int, OffsetPage<_Item>> pages;
  final requested = <int>[];
  Object? failPage;
  Completer<void>? gate;

  @override
  String itemKey(_Item item) => item.id;

  @override
  Future<OffsetPage<_Item>> fetchPage(int page) async {
    requested.add(page);
    final hold = gate;
    if (hold != null) await hold.future;
    if (failPage == page) throw StateError('offline');
    return pages[page] ?? (items: const <_Item>[], page: page, hasNext: false);
  }
}

void main() {
  test('refresh replaces; append accumulates and respects hasNext', () async {
    final notifier = _FakeNotifier({
      0: (
        items: const [_Item('a'), _Item('b')],
        page: 0,
        hasNext: true,
      ),
      1: (
        items: const [_Item('c')],
        page: 1,
        hasNext: false,
      ),
    });
    await notifier.load();
    expect(notifier.state.items.map((e) => e.id), ['a', 'b']);
    expect(notifier.state.page, 0);
    expect(notifier.state.hasNext, isTrue);

    await notifier.load();
    expect(notifier.state.items.map((e) => e.id), ['a', 'b', 'c']);
    expect(notifier.state.hasNext, isFalse);
    expect(notifier.requested, [0, 1]);

    notifier.pages[0] = (
      items: const [_Item('x')],
      page: 0,
      hasNext: false,
    );
    await notifier.load(refresh: true);
    expect(notifier.state.items.map((e) => e.id), ['x']);
    expect(notifier.state.hasNext, isFalse);
    notifier.dispose();
  });

  test('append dedupes overlapping ids from page drift', () async {
    final notifier = _FakeNotifier({
      0: (items: const [_Item('a')], page: 0, hasNext: true),
      1: (items: const [_Item('a'), _Item('b')], page: 1, hasNext: false),
    });
    await notifier.load();
    await notifier.load();
    expect(notifier.state.items.map((e) => e.id), ['a', 'b']);
    notifier.dispose();
  });

  test('failed load keeps prior items and exposes error', () async {
    final notifier = _FakeNotifier({
      0: (items: const [_Item('a')], page: 0, hasNext: true),
    });
    await notifier.load();
    notifier.failPage = 1;
    await notifier.load();
    expect(notifier.state.items.map((e) => e.id), ['a']);
    expect(notifier.state.error, isNotNull);
    expect(notifier.state.hasNext, isTrue);
    notifier.dispose();
  });

  test('refresh during load-more is queued and replaces stale pages', () async {
    final notifier = _FakeNotifier({
      0: (items: const [_Item('old-0')], page: 0, hasNext: true),
      1: (items: const [_Item('old-1')], page: 1, hasNext: false),
    });
    await notifier.load();
    expect(notifier.state.items.map((e) => e.id), ['old-0']);

    final hold = Completer<void>();
    notifier.gate = hold;
    final append = notifier.load(); // page 1 in flight
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.loading, isTrue);

    // SSE / fallback refresh while append is still loading.
    notifier.pages[0] = (
      items: const [_Item('fresh-0')],
      page: 0,
      hasNext: false,
    );
    unawaited(notifier.load(refresh: true));
    expect(notifier.requested, [0, 1]); // refresh not started yet

    hold.complete();
    await append;
    // Pending head refresh runs after append; wait for it.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    while (notifier.state.loading) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(notifier.requested, [0, 1, 0]);
    expect(notifier.state.items.map((e) => e.id), ['fresh-0']);
    expect(notifier.state.hasNext, isFalse);
    notifier.dispose();
  });
}
