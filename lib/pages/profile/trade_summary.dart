import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trade_provider.dart';

/// Customer statistics from /order/stats; this is not a marketplace menu.
class TradeSummary extends ConsumerWidget {
  const TradeSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradeStatsProvider);
    final stats = state.asData?.value;
    final scheme = Theme.of(context).colorScheme;
    final entries = [
      (
        '发布需求',
        stats?.publishedTaskCount,
        Icons.inventory_2_outlined,
        const Color(0xFF5586E8),
        'published',
      ),
      (
        '累计订单',
        stats?.totalOrderCount,
        Icons.receipt_long_outlined,
        const Color(0xFF20A68B),
        'orders',
      ),
      (
        '完成交易',
        stats?.completedTradeCount,
        Icons.task_alt_rounded,
        const Color(0xFF528FF5),
        'completed',
      ),
      (
        '待评价',
        stats?.pendingReviewCount,
        Icons.chat_bubble_outline_rounded,
        const Color(0xFFE6A047),
        'review',
      ),
    ];
    return Material(
      key: const ValueKey('profile-trade-summary'),
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '我的交易',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (state.hasError)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '统计暂未加载',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(tradeStatsProvider),
                    child: const Text('重试'),
                  ),
                ],
              ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => Expanded(
                      child: Column(
                        key: ValueKey('trade-${entry.$5}'),
                        children: [
                          Icon(entry.$3, size: 27, color: entry.$4),
                          const SizedBox(height: 8),
                          Text(
                            entry.$2?.toString() ?? '—',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.$1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
