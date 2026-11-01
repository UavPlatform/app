import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/widgets/infinite_list.dart';

void main() {
  testWidgets('InfiniteList triggers onLoadMore near the bottom', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfiniteList(
            itemCount: 30,
            hasMore: true,
            loadingMore: false,
            loadMoreExtent: 80,
            onLoadMore: () => loads++,
            itemBuilder: (_, i) => SizedBox(
              height: 60,
              child: Text('item-$i', key: ValueKey('item-$i')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Short viewport may already fire fill-if-short; reset baseline.
    final beforeScroll = loads;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('item-29')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(loads, greaterThan(beforeScroll));
  });

  testWidgets('LoadMoreListener fires when outer list hits bottom', (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadMoreListener(
            canLoadMore: true,
            extent: 40,
            onLoadMore: () => loads++,
            child: ListView.builder(
              itemCount: 40,
              itemBuilder: (_, i) => SizedBox(
                height: 50,
                child: Text('row-$i', key: ValueKey('row-$i')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = loads;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('row-39')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(loads, greaterThan(before));
  });
}
