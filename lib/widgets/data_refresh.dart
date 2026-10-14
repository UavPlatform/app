import 'package:flutter/material.dart';

/// Keeps pull-to-refresh available on short lists, empty states and errors.
class DataRefresh extends StatelessWidget {
  const DataRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.scrollable = false,
  });
  final Future<void> Function() onRefresh;
  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: scrollable
        ? child
        : LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: child,
              ),
            ),
          ),
  );
}
