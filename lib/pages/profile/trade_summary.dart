import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trade_provider.dart';

class TradeSummary extends ConsumerWidget {
  const TradeSummary({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradeStatsProvider);
    final stats = state.asData?.value;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final entries = [
      (
        '我发布的',
        Icons.inventory_2_outlined,
        stats?.publishedTaskCount,
        'published',
        const Color(0xFF5586E8),
      ),
      (
        '我卖出的',
        Icons.currency_yuan_rounded,
        stats?.soldOrderCount,
        'sold',
        const Color(0xFF20A68B),
      ),
      (
        '我买到的',
        Icons.assignment_turned_in_outlined,
        stats?.boughtOrderCount,
        'bought',
        const Color(0xFF528FF5),
      ),
      (
        '待评价',
        Icons.chat_bubble_outline_rounded,
        stats?.pendingReviewCount,
        'review',
        const Color(0xFFE6A047),
      ),
    ];
    return Material(
      key: const ValueKey('profile-trade-summary'),
      color: dark ? const Color(0xFF1B2735) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '我的交易',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  stats == null
                      ? '查看任务与交易进度'
                      : '已完成 ${stats.completedTradeCount} 笔 · 累计 ${stats.totalOrderCount} 单',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
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
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => Expanded(
                      child: InkWell(
                        key: ValueKey('trade-${entry.$4}'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          await context.push('/trade/${entry.$4}');
                          if (context.mounted) {
                            ref.invalidate(tradeStatsProvider);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 2,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 38,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      entry.$2,
                                      size: 29,
                                      color: dark
                                          ? Color.lerp(
                                              entry.$5,
                                              Colors.white,
                                              .2,
                                            )
                                          : entry.$5,
                                    ),
                                    if (entry.$3 != null && entry.$3! > 0)
                                      Positioned(
                                        top: -5,
                                        right: -18,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: dark
                                                ? const Color(0xFF304666)
                                                : const Color(0xFFEAF1FF),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            entry.$3! > 99
                                                ? '99+'
                                                : '${entry.$3}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: dark
                                                  ? const Color(0xFFACCCFF)
                                                  : const Color(0xFF3776D4),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.$1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurface,
                                ),
                              ),
                              if (entry.$3 == 0)
                                Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
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
