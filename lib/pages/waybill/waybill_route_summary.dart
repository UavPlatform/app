import 'package:flutter/material.dart';
import '../../models/waybill_draft.dart';
import 'waybill_edit_group.dart';
import 'waybill_section_surface.dart';

class WaybillRouteSummary extends StatelessWidget {
  const WaybillRouteSummary({
    super.key,
    required this.draft,
    required this.errors,
    required this.onEdit,
  });
  final WaybillDraft draft;
  final Map<String, String> errors;
  final ValueChanged<WaybillEditGroup> onEdit;

  Widget _point(String prefix, String label) {
    final group = WaybillEditGroup.site(prefix).first;
    final summary = group.summary(draft);
    final invalid = group.keys.any(errors.containsKey);
    return InkWell(
      key: ValueKey('edit-${group.id}'),
      onTap: () => onEdit(group),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: prefix == 'start'
                    ? const Color(0xFFE8F0FE)
                    : const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: prefix == 'start'
                      ? const Color(0xFF1D6FE9)
                      : const Color(0xFFFF6B00),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.isEmpty
                        ? (prefix == 'start' ? '选择起吊位置' : '选择送达位置')
                        : draft.value('$prefix.place').isNotEmpty
                        ? draft.value('$prefix.place')
                        : draft.value('$prefix.site').isEmpty
                        ? '已选择位置'
                        : draft.value('$prefix.site'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invalid
                        ? group.errors(draft).values.firstOrNull ?? '请选择地图位置'
                        : summary.isEmpty
                        ? '点击地图选点'
                        : summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => WaybillSectionSurface(
    title: '吊运路线',
    icon: Icons.route_outlined,
    first: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _point('start', '起'),
        Padding(
          padding: const EdgeInsets.only(left: 28.25),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 1.5,
              height: 16,
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    const SizedBox(
                      width: 1.5,
                      height: 4,
                      child: ColoredBox(color: Color(0xFFDCDFE6)),
                    ),
                    if (i < 2) const SizedBox(height: 2),
                  ],
                ],
              ),
            ),
          ),
        ),
        _point('end', '终'),
      ],
    ),
  );
}
