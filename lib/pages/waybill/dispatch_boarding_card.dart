import 'package:flutter/material.dart';
import '../../models/dispatch_order.dart';
import '../../theme/dispatch_palette.dart';
import '../../widgets/flow_ui.dart';
import '../../widgets/hud_surface.dart';
import 'dispatch_tracking_timeline.dart';

class DispatchBoardingCard extends StatelessWidget {
  const DispatchBoardingCard({
    super.key,
    required this.order,
    required this.selected,
    required this.onTap,
    required this.onDetails,
  });
  final DispatchOrder order;
  final bool selected;
  final VoidCallback onTap, onDetails;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final accent = DispatchPalette.status(context, order.data.stage);
    final fields = order.data.fields ?? const <String, dynamic>{};
    String field(String key, String fallback) =>
        fields[key]?.toString().trim().isNotEmpty == true
        ? fields[key].toString()
        : fallback;
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF23312F) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: dark ? scheme.outlineVariant : hudBorder),
        boxShadow: [
          BoxShadow(
            color: hudInk.withValues(alpha: selected ? .07 : .025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [hudTeal, hudAmber]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: hudTeal,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          field('category', '吊运任务'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: order.transporting && !dark
                              ? const Color(0xFFFFF3E8)
                              : accent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (order.transporting) ...[
                              const HudPulse(color: Color(0xFFD95B00), size: 5),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              order.stageLabel,
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              selected
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 15,
                              color: accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: _PlaceBadge(
                          label: '起',
                          name: field(
                            'start.address',
                            field('start.site', '起点待补充'),
                          ),
                          color: hudTeal,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFCEC9BF),
                                    thickness: 1,
                                  ),
                                ),
                                SizedBox(width: 18),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFCEC9BF),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            Transform.rotate(
                              angle: 1.5708,
                              child: const Icon(
                                Icons.flight_rounded,
                                size: 15,
                                color: hudAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _PlaceBadge(
                          label: '终',
                          name: field(
                            'end.address',
                            field('end.site', '终点待补充'),
                          ),
                          color: hudAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '运单 ${shortReference(order.id)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: OutlinedButton(
              onPressed: onDetails,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                backgroundColor: dark ? scheme.surfaceContainer : hudSand,
                foregroundColor: dark ? scheme.secondary : hudTeal,
                side: const BorderSide(color: hudBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '查看进度',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: DispatchTrackingTimeline(order: order),
            ),
        ],
      ),
    );
  }
}

class _PlaceBadge extends StatelessWidget {
  const _PlaceBadge({
    required this.label,
    required this.name,
    required this.color,
  });
  final String label, name;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Tooltip(
          message: name,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}
