import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Scroll-wheel style time picker as a bottom sheet.
Future<TimeOfDay?> showScrollTimePicker(BuildContext context, {TimeOfDay? initial}) {
  final init = initial ?? TimeOfDay.now();
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TimePickerSheet(initial: init),
  );
}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay initial;
  const _TimePickerSheet({required this.initial});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;
  late int _hour, _minute;

  static const _itemH = 44.0;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minute = widget.initial.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(fontSize: 15)),
                ),
                const Text('选择时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
                  child: const Text('确定', style: TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Wheels
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: _buildWheel(24, _hourCtrl, (v) => _hour = v, '时')),
                  Container(
                    padding: const EdgeInsets.only(top: _itemH),
                    child: const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: AppColors.textPrimary)),
                  ),
                  Expanded(child: _buildWheel(60, _minuteCtrl, (v) => _minute = v, '分')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(int count, FixedExtentScrollController controller, ValueChanged<int> onChanged, String suffix) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemH,
      diameterRatio: 2.0,
      perspective: 0.004,
      onSelectedItemChanged: onChanged,
      physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (context, index) {
          return Center(
            child: Text(
              '${index.toString().padLeft(2, '0')}$suffix',
              style: const TextStyle(fontSize: 17, color: AppColors.textPrimary),
            ),
          );
        },
        childCount: count,
      ),
    );
  }
}
