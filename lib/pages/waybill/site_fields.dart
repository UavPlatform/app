import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/waybill_draft.dart';
import 'waybill_fields.dart';

class SiteFields extends StatelessWidget {
  const SiteFields({
    super.key,
    required this.draft,
    required this.prefix,
    required this.onChanged,
    required this.errors,
  });
  final WaybillDraft draft;
  final String prefix;
  final DraftChanged onChanged;
  final Map<String, String> errors;

  Future<void> _pick(BuildContext context) async {
    final route = prefix == 'start' ? '/map/pick?point=start' : '/map/pick';
    final result = await context.push<String>(route);
    if (!context.mounted || result == null) return;
    final parts = result.split(';');
    final coordinates = parts.first.split(',');
    if (coordinates.length != 2) return;
    onChanged('$prefix.lat', coordinates[0]);
    onChanged('$prefix.lng', coordinates[1]);
    // 地点名称/地址只作本地展示（不在 cloudFieldNames 内，不会提交给后端）。
    final name = parts.length > 1 ? parts[1].trim() : '';
    onChanged('$prefix.place', name);
    onChanged('$prefix.placeAddress', parts.length > 2 ? parts[2].trim() : '');
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String name, String label, {bool numeric = false}) =>
        WaybillField(
          draft: draft,
          name: '$prefix.$name',
          label: label,
          numeric: numeric,
          errors: errors,
          onChanged: onChanged,
        );
    final landing = draft.value('$prefix.landing');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: ValueKey('$prefix.pick'),
          onPressed: () => _pick(context),
          icon: const Icon(Icons.place_outlined),
          label: Text(
            draft.value('$prefix.lat').isEmpty
                ? '在地图上选择${prefix == 'start' ? '起点' : '终点'}'
                : draft.value('$prefix.place').isEmpty
                ? '${draft.value('$prefix.lat')}, ${draft.value('$prefix.lng')}'
                : '${draft.value('$prefix.place')} · ${draft.value('$prefix.lat')}, ${draft.value('$prefix.lng')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (errors['$prefix.point'] != null)
          Text(
            errors['$prefix.point']!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 16),
        field('site', '场地类型', numeric: false),
        Text('场地能否降落？', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ChoiceChip(
              label: const Text('能 · 落地放货'),
              selected: landing == 'yes',
              onSelected: (_) => onChanged('$prefix.landing', 'yes'),
            ),
            ChoiceChip(
              label: const Text('不能 · 绞盘吊放'),
              selected: landing == 'no',
              onSelected: (_) => onChanged('$prefix.landing', 'no'),
            ),
          ],
        ),
        if (errors['$prefix.landing'] != null)
          Text(
            errors['$prefix.landing']!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 16),
        if (landing == 'no') ...[
          field('winchMin', '绞盘高度下限（m）', numeric: true),
          field('winchMax', '绞盘高度上限（m）', numeric: true),
        ],
        field('contact', '现场联系人姓名'),
        field('phone', '现场联系人电话'),
        field('notes', '现场备注（选填）'),
      ],
    );
  }
}
