import 'package:flutter/material.dart';
import '../../models/waybill_draft.dart';
import 'waybill_layout.dart';

typedef DraftChanged = void Function(String key, String value);

class WaybillField extends StatelessWidget {
  const WaybillField({
    super.key,
    required this.draft,
    required this.name,
    required this.label,
    required this.onChanged,
    this.errors = const {},
    this.numeric = false,
    this.lines = 1,
    this.hint,
    this.compact = false,
  });
  final WaybillDraft draft;
  final String name, label;
  final DraftChanged onChanged;
  final Map<String, String> errors;
  final bool numeric, compact;
  final int lines;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 0 : 16),
    child: TextFormField(
      key: ValueKey(name),
      initialValue: draft.value(name),
      onChanged: (value) => onChanged(name, value),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: lines,
      style: compact
          ? const TextStyle(fontSize: 14, color: Color(0xFF1D2129))
          : null,
      decoration: compact
          ? compactDecoration(context, hint ?? label, errors[name])
          : InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: errors[name],
              border: const OutlineInputBorder(),
            ),
    ),
  );
}

InputDecoration compactDecoration(
  BuildContext context,
  String hint,
  String? error,
) {
  final colors = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    errorText: error,
    errorMaxLines: 3,
    isDense: true,
    filled: false,
    hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    border: border(colors.outlineVariant),
    enabledBorder: border(colors.outlineVariant),
    focusedBorder: border(colors.primary, 1.5),
    errorBorder: border(colors.error),
    focusedErrorBorder: border(colors.error, 1.5),
  );
}

class CargoFields extends StatelessWidget {
  const CargoFields({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.errors,
    this.section,
  });
  final WaybillDraft draft;
  final DraftChanged onChanged;
  final Map<String, String> errors;
  final int? section;

  @override
  Widget build(BuildContext context) {
    Widget field(
      String name,
      String label, {
      bool numeric = false,
      String? hint,
    }) => WaybillField(
      draft: draft,
      name: name,
      label: label,
      numeric: numeric,
      hint: hint,
      errors: errors,
      onChanged: onChanged,
      compact: true,
    );
    const heading = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1D2129),
    );
    const caption = TextStyle(fontSize: 12, color: Color(0xFF4E5969));
    Widget group(String title, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(title, style: caption),
        child,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (section == null || section == 0)
          WaybillSection(
            children: [
              const Text('货物类别', style: heading),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in WaybillDraft.categories)
                    ChoiceChip(
                      label: Text(category),
                      selected: draft.value('category') == category,
                      onSelected: (_) => onChanged('category', category),
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 4,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 7),
                      backgroundColor: const Color(0xFFF2F3F5),
                      selectedColor: const Color(0xFFE8F3FF),
                      side: BorderSide(
                        color: draft.value('category') == category
                            ? waybillBlue
                            : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: draft.value('category') == category
                            ? waybillBlue
                            : const Color(0xFF4E5969),
                        fontWeight: draft.value('category') == category
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  CustomPaint(
                    foregroundPainter: const DashedCategoryBorder(),
                    child: ChoiceChip(
                      label: const Text('危险品 · 暂不开放'),
                      selected: false,
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      disabledColor: const Color(0xFFF2F3F5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 4,
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA2A9B3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              if (errors['category'] != null)
                Text(
                  errors['category']!,
                  style: const TextStyle(
                    color: Color(0xFFF53F3F),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        if (section == null || section == 1)
          WaybillSection(
            children: [
              const Text('重量与规格', style: heading),
              group(
                '重量范围 (kg)',
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field('weightMin', '下限', numeric: true)),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Text('~', style: caption),
                    ),
                    Expanded(
                      child: field('weightMax', '上限（选填）', numeric: true),
                    ),
                  ],
                ),
              ),
              group(
                '尺寸规格 (cm)',
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field('length', '长度', numeric: true)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 9),
                      child: Text('×', style: caption),
                    ),
                    Expanded(child: field('width', '宽度', numeric: true)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 9),
                      child: Text('×', style: caption),
                    ),
                    Expanded(child: field('height', '高度', numeric: true)),
                  ],
                ),
              ),
              _CargoQuantity(
                draft: draft,
                onChanged: onChanged,
                errors: errors,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 9, right: 14),
                    child: Text('包装说明', style: caption),
                  ),
                  Expanded(child: field('packaging', '例如：木箱、纸箱或托盘')),
                ],
              ),
            ],
          ),
        if (section == null || section == 2)
          WaybillSection(
            children: [
              const Text('作业补充', style: heading),
              group('吊点说明', field('lifting', '填写吊点位置与固定方式')),
              group(
                '货值（元，选填）',
                field('declaredValue', '填写申报货值', numeric: true),
              ),
            ],
          ),
      ],
    );
  }
}

/// Controller is confined to the stepper's visual text editor. The existing
/// draft count and onChanged callback remain the only business data binding.
class _CargoQuantity extends StatefulWidget {
  const _CargoQuantity({
    required this.draft,
    required this.onChanged,
    required this.errors,
  });
  final WaybillDraft draft;
  final DraftChanged onChanged;
  final Map<String, String> errors;
  @override
  State<_CargoQuantity> createState() => _CargoQuantityState();
}

class _CargoQuantityState extends State<_CargoQuantity> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.draft.value('count'));
  }

  @override
  void didUpdateWidget(covariant _CargoQuantity oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.draft.value('count');
    if (_controller.text != value) {
      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.draft.value('count');
    final count = int.tryParse(raw);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 9),
            child: Text(
              '件数',
              style: TextStyle(fontSize: 13, color: Color(0xFF4E5969)),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: '减少件数',
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            visualDensity: VisualDensity.compact,
            backgroundColor: const Color(0xFFF2F3F5),
            foregroundColor: const Color(0xFF4E5969),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: count != null && count > 1
              ? () => widget.onChanged('count', '${count - 1}')
              : null,
          icon: const Icon(Icons.remove, size: 16),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 66,
          child: TextFormField(
            key: const ValueKey('count'),
            controller: _controller,
            onChanged: (value) => widget.onChanged('count', value),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1D2129)),
            decoration: compactDecoration(
              context,
              '数量',
              widget.errors['count'],
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: '增加件数',
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            visualDensity: VisualDensity.compact,
            backgroundColor: const Color(0xFFE8F3FF),
            foregroundColor: waybillBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: raw.isEmpty || count != null && count > 0
              ? () => widget.onChanged('count', '${(count ?? 0) + 1}')
              : null,
          icon: const Icon(Icons.add, size: 16),
        ),
      ],
    );
  }
}
