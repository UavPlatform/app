import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/dispatch_order.dart';
import '../../widgets/dispatch_stage_progress.dart';
import '../../widgets/flow_ui.dart';

class DispatchOrderAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DispatchOrderAppBar({
    super.key,
    required this.title,
    required this.onReturn,
    required this.onRefresh,
  });

  final String title;
  final VoidCallback onReturn;
  final VoidCallback onRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF111111),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    toolbarHeight: kToolbarHeight,
    leading: BackButton(onPressed: Navigator.canPop(context) ? null : onReturn),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111111),
      ),
    ),
    actions: [
      IconButton(
        tooltip: '刷新订单',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class DispatchOrderStatusStrip extends StatelessWidget {
  const DispatchOrderStatusStrip({super.key, required this.order, this.step});

  final DispatchOrder order;
  final int? step;
  static const _blue = Color(0xFF1D6FE9);

  @override
  Widget build(BuildContext context) {
    final current = step;
    final labels = DispatchStageProgress.labels;
    return Card(
      margin: const EdgeInsets.only(top: 4),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    spacing: 2,
                    children: [
                      Flexible(
                        child: Text(
                          '运单 ${shortReference(order.id)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '复制运单号',
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 24,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: _blue,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: order.id),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('运单号已复制')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (current != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        '进度 ${current + 1} / ${labels.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (current != null)
              Semantics(
                label:
                    '订单进度，第 ${current + 1} 步，共 ${labels.length} 步，${labels[current]}',
                child: Row(
                  spacing: 4,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Tooltip(
                          message: labels[i],
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= current
                                  ? _blue
                                  : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DispatchOrderGuide extends StatelessWidget {
  const DispatchOrderGuide(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFF0F6FF),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: Color(0xFF1D6FE9)),
      ),
    ),
  );
}
