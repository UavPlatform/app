import 'package:flutter/material.dart';
import '../../models/dispatch_order.dart';

const _blue = Color(0xFF1D6FE9);

class DispatchHallWorkbench extends StatelessWidget {
  const DispatchHallWorkbench({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(colors: [_blue, Color(0xFF2563EB)]),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择你的下一单',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF6EE7B7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '实时听单中',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Whole labels wrap together on narrow screens instead of splitting words.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final rule in const ['⚡ 先接者得', '🔒 接单解锁联系', '📦 按阶段交付'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rule,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class DispatchHallEmptyState extends StatelessWidget {
  const DispatchHallEmptyState({super.key, required this.onNearby});
  final VoidCallback onNearby;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F3FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.radar_rounded, size: 36, color: _blue),
        ),
        const SizedBox(height: 16),
        const Text(
          '暂无待接订单',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2329),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '系统正在实时监听周边需求，您也可以查看附近订单',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: onNearby,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFF2F4F7),
            foregroundColor: _blue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: const Text('查看附近订单'),
        ),
      ],
    ),
  );
}

class DispatchHallOfferCard extends StatelessWidget {
  const DispatchHallOfferCard({
    super.key,
    required this.offer,
    required this.onClaim,
  });
  final DispatchOffer offer;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final fields = offer.data.fields ?? const <String, String>{};
    final fee = offer.data.pilotServiceFee;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fields['category'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fields['timeMode'] == 'scheduled'
                          ? '预约：${fields['scheduledAt']}'
                          : '立即出发',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              if (fee != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${fee.toStringAsFixed(2)}/单',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '飞手服务费',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _RouteSite(
            label: '起',
            site: fields['start.site'] ?? '',
            background: const Color(0xFFE8F3FF),
            foreground: _blue,
          ),
          const SizedBox(height: 12),
          _RouteSite(
            label: '终',
            site: fields['end.site'] ?? '',
            background: const Color(0xFFFFF0E6),
            foreground: const Color(0xFFFF6B00),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${dispatchWeightLabel(fields)} · ${fields['count'] ?? ''} 件',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onClaim,
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('立即接单'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '接单后查看联系人与场地 · 净收入及建议机型暂未提供',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSite extends StatelessWidget {
  const _RouteSite({
    required this.label,
    required this.site,
    required this.background,
    required this.foreground,
  });
  final String label, site;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          site,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2329),
          ),
        ),
      ),
    ],
  );
}
