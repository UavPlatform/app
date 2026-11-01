import 'package:flutter/material.dart';
import '../../models/waybill_draft.dart';
import 'waybill_edit_group.dart';
import 'waybill_route_summary.dart';
import 'waybill_section_surface.dart';

class WaybillSummary extends StatelessWidget {
  const WaybillSummary({
    super.key,
    required this.draft,
    required this.errors,
    required this.onEdit,
  });
  final WaybillDraft draft;
  final Map<String, String> errors;
  final ValueChanged<WaybillEditGroup> onEdit;

  Widget _buildFormRow({
    Key? key,
    required String label,
    required String value,
    bool isPlaceholder = false,
    VoidCallback? onTap,
  }) => InkWell(
    key: key,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF222222),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w500,
                color: isPlaceholder
                    ? const Color(0xFF999999)
                    : const Color(0xFF1F2329),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
        ],
      ),
    ),
  );

  Widget _section(String title, IconData icon, List<WaybillEditGroup> groups) =>
      WaybillSectionSurface(
        title: title,
        icon: icon,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final group in groups) _groupRow(group)],
        ),
      );

  Widget _groupRow(WaybillEditGroup group) {
    final summary = group.summary(draft);
    final invalid = group.keys.any(errors.containsKey);
    final emptyPhotos =
        group.photos != null &&
        !draft.fields.entries.any(
          (e) =>
              e.key.startsWith('${group.photos}.photo.') && e.value.isNotEmpty,
        );
    return _buildFormRow(
      key: ValueKey('edit-${group.id}'),
      label: group.title,
      value: invalid
          ? group.errors(draft).values.firstOrNull ?? '请检查信息'
          : summary.isEmpty
          ? '点击填写'
          : summary,
      isPlaceholder: !invalid && (summary.isEmpty || emptyPhotos),
      onTap: () => onEdit(group),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      WaybillRouteSummary(draft: draft, errors: errors, onEdit: onEdit),
      _section('货物信息', Icons.inventory_2_outlined, WaybillEditGroup.cargo),
      _section(
        '起点现场',
        Icons.flight_takeoff,
        WaybillEditGroup.site('start').skip(1).toList(),
      ),
      _section(
        '终点现场',
        Icons.flight_land,
        WaybillEditGroup.site('end').skip(1).toList(),
      ),
      _section('出发安排', Icons.schedule_outlined, const [WaybillEditGroup.time]),
    ],
  );
}
