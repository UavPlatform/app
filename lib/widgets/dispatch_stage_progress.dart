import 'package:flutter/material.dart';

class DispatchStageProgress extends StatelessWidget {
  const DispatchStageProgress({super.key, required this.current});
  final int current;
  static const labels = ['下单', '等待接单', '飞手准备中', '飞手到场', '运输中', '送达双确认', '已结单'];
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, color: scheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '订单进度',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${current + 1} / ${labels.length}',
                  style: TextStyle(color: scheme.primary),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: (current + 1) / labels.length,
              color: scheme.secondary,
              backgroundColor: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
              minHeight: 6,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Semantics(
                        selected: i == current,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: i == current
                                ? scheme.primaryContainer
                                : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${i + 1} ${labels[i]}',
                            style: TextStyle(
                              color: i <= current
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              fontWeight: i == current
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
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
