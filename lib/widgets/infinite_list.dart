import 'package:flutter/material.dart';

/// Watches vertical scroll and fires [onLoadMore] near the bottom.
///
/// Safe to wrap an outer [ListView] that embeds a nested section — it only
/// reacts to notifications that bubble from this subtree's scrollables.
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({
    super.key,
    required this.canLoadMore,
    required this.onLoadMore,
    required this.child,
    this.extent = 240,
  });

  final bool canLoadMore;
  final VoidCallback onLoadMore;
  final Widget child;
  final double extent;

  bool _handle(ScrollNotification notification) {
    if (!canLoadMore) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    final metrics = notification.metrics;
    if (!metrics.hasPixels || !metrics.hasContentDimensions) return false;
    if (metrics.pixels >= metrics.maxScrollExtent - extent) {
      onLoadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _handle,
        child: child,
      );
}

/// Bottom status row for infinite lists.
class InfiniteListFooter extends StatelessWidget {
  const InfiniteListFooter({
    super.key,
    required this.loading,
    required this.hasMore,
    this.endMessage = '没有更多了',
    this.showEndMessage = true,
  });

  final bool loading;
  final bool hasMore;
  final String endMessage;
  final bool showEndMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!hasMore && showEndMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            endMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

/// RefreshIndicator + ListView with end-reached loading.
class InfiniteList extends StatefulWidget {
  const InfiniteList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
    this.loadingMore = false,
    this.padding = const EdgeInsets.all(16),
    this.physics,
    this.controller,
    this.header,
    this.empty,
    this.separatorHeight = 16,
    this.loadMoreExtent = 240,
    this.endMessage = '没有更多了',
    this.showEndMessage = true,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool loadingMore;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final Widget? header;
  final Widget? empty;
  final double separatorHeight;
  final double loadMoreExtent;
  final String endMessage;
  final bool showEndMessage;

  @override
  State<InfiniteList> createState() => _InfiniteListState();
}

class _InfiniteListState extends State<InfiniteList> {
  ScrollController? _owned;
  ScrollController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = ScrollController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillIfShort());
  }

  @override
  void didUpdateWidget(covariant InfiniteList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.hasMore != widget.hasMore ||
        oldWidget.loadingMore != widget.loadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillIfShort());
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  void _fillIfShort() {
    if (!mounted || widget.onLoadMore == null) return;
    if (!widget.hasMore || widget.loadingMore) return;
    if (!_controller.hasClients) return;
    final extent = _controller.position.maxScrollExtent;
    if (extent <= widget.loadMoreExtent) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showEmpty = widget.itemCount == 0 && widget.empty != null;
    final children = <Widget>[
      if (widget.header != null) widget.header!,
      if (showEmpty)
        widget.empty!
      else ...[
        for (var i = 0; i < widget.itemCount; i++) ...[
          if (i > 0) SizedBox(height: widget.separatorHeight),
          widget.itemBuilder(context, i),
        ],
      ],
      if (!showEmpty && (widget.hasMore || widget.loadingMore || widget.itemCount > 0))
        InfiniteListFooter(
          loading: widget.loadingMore,
          hasMore: widget.hasMore,
          endMessage: widget.endMessage,
          showEndMessage: widget.showEndMessage && widget.itemCount > 0,
        ),
    ];

    final list = LoadMoreListener(
      canLoadMore:
          widget.hasMore && !widget.loadingMore && widget.onLoadMore != null,
      onLoadMore: widget.onLoadMore ?? () {},
      extent: widget.loadMoreExtent,
      child: ListView(
        controller: _controller,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        children: children,
      ),
    );

    final refresh = widget.onRefresh;
    if (refresh == null) return list;
    return RefreshIndicator(onRefresh: refresh, child: list);
  }
}
