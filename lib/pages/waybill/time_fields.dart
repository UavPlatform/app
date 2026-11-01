import 'package:flutter/material.dart';

import '../../models/waybill_draft.dart';
import 'waybill_fields.dart';
import '../../widgets/scroll_pickers.dart';

class TimeFields extends StatelessWidget {
  const TimeFields({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.errors,
  });
  final WaybillDraft draft;
  final DraftChanged onChanged;
  final Map<String, String> errors;

  String get _scheduledLabel {
    final value = DateTime.tryParse(draft.value('scheduledAt'));
    return value == null
        ? '选择预约日期与时间'
        : value.toIso8601String().replaceAll('T', ' ').substring(0, 16);
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final old = DateTime.tryParse(draft.value('scheduledAt'));
    final date = await showScrollDatePicker(
      context,
      initial: old != null && old.isAfter(now) ? old : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );
    if (!context.mounted || date == null) return;
    final time = await showScrollTimePicker(
      context,
      initial: TimeOfDay.fromDateTime(old ?? now),
    );
    if (!context.mounted || time == null) return;
    onChanged(
      'scheduledAt',
      DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ).toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('立即出发'),
            selected: draft.value('timeMode') == 'now',
            onSelected: (_) => onChanged('timeMode', 'now'),
          ),
          ChoiceChip(
            label: const Text('预约时间'),
            selected: draft.value('timeMode') == 'scheduled',
            onSelected: (_) => onChanged('timeMode', 'scheduled'),
          ),
        ],
      ),
      if (errors['timeMode'] != null)
        Text(
          errors['timeMode']!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (draft.value('timeMode') == 'scheduled') ...[
        OutlinedButton(
          onPressed: () => _pick(context),
          child: Text(_scheduledLabel),
        ),
        if (errors['scheduledAt'] != null)
          Text(
            errors['scheduledAt']!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('加急'),
        value: draft.value('urgent') == 'yes',
        onChanged: (value) => onChanged('urgent', value ? 'yes' : 'no'),
      ),
    ],
  );
}
