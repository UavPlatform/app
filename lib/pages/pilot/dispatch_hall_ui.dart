import 'package:flutter/material.dart';
import '../../models/dispatch_order.dart';

const _blue = Color(0xFF1D6FE9);

class DispatchHallWorkbench extends StatelessWidget {
  const DispatchHallWorkbench({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: Row(
      spacing: 6,
      children: [
        Icon(Icons.radar_rounded, color: _blue, size: 18),
        Text('可接订单', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class DispatchHallEmptyState extends StatelessWidget {
  const DispatchHallEmptyState({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
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
          '有新订单时会显示在这里',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: onRefresh,
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
          child: const Text('刷新大厅'),
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
    this.distanceMeters,
    this.highlighted = false,
  });
  final DispatchOffer offer;
  final VoidCallback? onClaim;
  final double? distanceMeters;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fields = offer.data.fields ?? const <String, String>{};
    final fee = offer.data.pilotServiceFee;
    final distance = distanceMeters;
    final scheduled = DateTime.tryParse(fields['scheduledAt'] ?? '')?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final time = fields['timeMode'] != 'scheduled'
        ? '立即出发'
        : scheduled == null
        ? '预约时间待确认'
        : '${localizations.formatCompactDate(scheduled)} ${TimeOfDay.fromDateTime(scheduled).format(context)}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              _decision(
                '预计报酬',
                fee == null ? '待确认' : '¥${fee.toStringAsFixed(2)}',
                color: const Color(0xFFD95700),
              ),
              _decision(
                '距起点',
                distance == null
                    ? '未定位'
                    : distance < 1000
                    ? '${distance.toStringAsFixed(0)} m'
                    : '${(distance / 1000).toStringAsFixed(1)} km',
              ),
              _decision('货重', dispatchWeightLabel(fields)),
              _decision('时间', time),
            ],
          ),
          const Divider(height: 1),
          _RouteSite(
            label: '起',
            site: fields['start.site'] ?? '起点待确认',
            background: const Color(0xFFE8F3FF),
            foreground: _blue,
          ),
          _RouteSite(
            label: '终',
            site: fields['end.site'] ?? '终点待确认',
            background: const Color(0xFFFFF0E6),
            foreground: const Color(0xFFD95700),
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  [
                        fields['category'],
                        if (fields['count']?.isNotEmpty == true)
                          '${fields['count']} 件',
                      ]
                      .whereType<String>()
                      .where((text) => text.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilledButton(onPressed: onClaim, child: const Text('立即接单')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decision(String label, String value, {Color? color}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        Tooltip(
          message: value,
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
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
