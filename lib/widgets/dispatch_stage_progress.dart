import 'package:flutter/material.dart';

class DispatchStageProgress extends StatelessWidget {
  const DispatchStageProgress({super.key, required this.current});
  final int current;
  static const labels = ['下单', '等待接单', '飞手准备中', '飞手到场', '运输中', '送达双确认', '已结单'];
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '订单进度，第 ${current + 1} 步，共 ${labels.length} 步，${labels[current]}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              children: [
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
            Row(
              spacing: 5,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Tooltip(
                      message: '${i + 1} ${labels[i]}',
                      child: Semantics(
                        label: labels[i],
                        selected: i == current,
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          height: i == current ? 10 : 6,
                          decoration: BoxDecoration(
                            color: i <= current
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
