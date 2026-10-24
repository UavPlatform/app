import '../../theme/dispatch_palette.dart';
import 'package:flutter/material.dart';
import '../../models/dispatch_order.dart';
import '../../models/dispatch_tracking.dart';

class DispatchTrackingTimeline extends StatelessWidget {
  const DispatchTrackingTimeline({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) {
    final steps = dispatchTrackingSteps(order);
    final scheme = Theme.of(context).colorScheme;
    final accent = DispatchPalette.status(context, order.data.stage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '订单跟踪',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '本轮进度 · ${order.stageLabel}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: steps[i].current
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: .22),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                          color: steps[i].current ? accent : scheme.surface,
                          border: Border.all(color: accent, width: 2),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: accent.withValues(alpha: .3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            steps[i].label,
                            style: TextStyle(
                              fontSize: 14,
                              color: steps[i].current
                                  ? accent
                                  : scheme.onSurface,
                              fontWeight: steps[i].current
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          dispatchTrackingTime(steps[i].time),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          '进度由订单业务状态更新；到场、运输和送达由飞手确认。',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
