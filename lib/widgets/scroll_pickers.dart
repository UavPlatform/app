import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Scroll-wheel date picker — centered dialog with scale-fade animation.
Future<DateTime?> showScrollDatePicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final now = DateTime.now();
  final init = initial ?? now.add(const Duration(days: 1));
  final first = firstDate ?? now;
  final last = lastDate ?? now.add(const Duration(days: 90));

  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
        child: FadeTransition(opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim), child: child));
    },
    pageBuilder: (_, __, ___) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _DatePickerSheet(initial: init, firstDate: first, lastDate: last),
      ),
    ),
  );
}

/// Scroll-wheel time picker — centered dialog with scale-fade animation.
Future<TimeOfDay?> showScrollTimePicker(BuildContext context, {TimeOfDay? initial}) {
  final init = initial ?? TimeOfDay.now();
  return showGeneralDialog<TimeOfDay>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
        child: FadeTransition(opacity: Tween<double>(begin: 0.0, end: 1.0).animate(anim), child: child));
    },
    pageBuilder: (_, __, ___) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _TimePickerSheet(initial: init),
      ),
    ),
  );
}

// ==================== Date picker ====================
class _DatePickerSheet extends StatefulWidget {
  final DateTime initial, firstDate, lastDate;
  const _DatePickerSheet({required this.initial, required this.firstDate, required this.lastDate});
  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late final FixedExtentScrollController _yearCtrl, _monthCtrl, _dayCtrl;
  late final List<int> _years, _months, _days;
  late int _yearIdx, _monthIdx, _dayIdx;
  static const _itemH = 44.0;

  @override
  void initState() {
    super.initState();
    _years = List.generate(widget.lastDate.year - widget.firstDate.year + 1, (i) => widget.firstDate.year + i);
    _yearIdx = _years.indexOf(widget.initial.year);
    _months = _monthsFor(_years[_yearIdx]);
    _monthIdx = _months.indexOf(widget.initial.month);
    if (_monthIdx < 0) _monthIdx = 0;
    _days = _daysFor(_years[_yearIdx], _months[_monthIdx]);
    _dayIdx = _days.indexOf(widget.initial.day);
    if (_dayIdx < 0) _dayIdx = 0;

    _yearCtrl = FixedExtentScrollController(initialItem: _yearIdx);
    _monthCtrl = FixedExtentScrollController(initialItem: _monthIdx);
    _dayCtrl = FixedExtentScrollController(initialItem: _dayIdx);
  }

  List<int> _monthsFor(int year) {
    final first = widget.firstDate; final last = widget.lastDate;
    int start = (year == first.year) ? first.month : 1;
    int end = (year == last.year) ? last.month : 12;
    return List.generate(end - start + 1, (i) => start + i);
  }

  List<int> _daysFor(int year, int month) {
    final first = widget.firstDate; final last = widget.lastDate;
    int start = (year == first.year && month == first.month) ? first.day : 1;
    int end = (year == last.year && month == last.month) ? last.day : _lastDayOfMonth(year, month);
    if (start > end) start = end;
    return List.generate(end - start + 1, (i) => start + i);
  }

  int _lastDayOfMonth(int year, int month) {
    if (month == 2) return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    return const [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  }

  @override
  void dispose() { _yearCtrl.dispose(); _monthCtrl.dispose(); _dayCtrl.dispose(); super.dispose(); }

  void _onYearChanged(int idx) {
    final oldMonth = _months.isNotEmpty ? _months[_monthIdx] : widget.firstDate.month;
    final newMonths = _monthsFor(_years[idx]);
    int newMonthIdx = newMonths.indexOf(oldMonth);
    if (newMonthIdx < 0) newMonthIdx = 0;
    final newDays = _daysFor(_years[idx], newMonths[newMonthIdx]);
    int newDayIdx = (_dayIdx < newDays.length) ? _dayIdx : newDays.length - 1;
    if (newDayIdx < 0) newDayIdx = 0;
    setState(() {
      _yearIdx = idx; _months.clear(); _months.addAll(newMonths);
      _monthIdx = newMonthIdx; _days.clear(); _days.addAll(newDays); _dayIdx = newDayIdx;
      _monthCtrl.jumpToItem(_monthIdx); _dayCtrl.jumpToItem(_dayIdx);
    });
  }

  void _onMonthChanged(int idx) {
    final newDays = _daysFor(_years[_yearIdx], _months[idx]);
    int newDayIdx = newDays.indexOf(_days.isNotEmpty ? _days[_dayIdx] : 1);
    if (newDayIdx < 0) newDayIdx = 0;
    setState(() { _monthIdx = idx; _days.clear(); _days.addAll(newDays); _dayIdx = newDayIdx; _dayCtrl.jumpToItem(_dayIdx); });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(fontSize: 15))),
              const Text('选择日期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => Navigator.pop(context, DateTime(_years[_yearIdx], _months[_monthIdx], _days[_dayIdx])),
                child: const Text('确定', style: TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(flex: 5, child: _buildWheel(_years.length, _yearCtrl, _onYearChanged, (i) => '${_years[i]}年')),
                Expanded(flex: 4, child: _buildWheel(_months.length, _monthCtrl, _onMonthChanged, (i) => '${_months[i]}月')),
                Expanded(flex: 4, child: _buildWheel(_days.length, _dayCtrl, (i) => _dayIdx = i, (i) => '${_days[i]}日')),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildWheel(int count, FixedExtentScrollController ctrl, ValueChanged<int> onChanged, String Function(int) label) {
    return ListWheelScrollView.useDelegate(
      controller: ctrl, itemExtent: _itemH, diameterRatio: 2.0, perspective: 0.004,
      onSelectedItemChanged: onChanged, physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (_, i) => Center(child: Text(label(i), style: const TextStyle(fontSize: 17))),
        childCount: count,
      ),
    );
  }
}

// ==================== Time picker ====================
class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay initial;
  const _TimePickerSheet({required this.initial});
  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late final FixedExtentScrollController _hourCtrl, _minuteCtrl;
  late int _hour, _minute;
  static const _itemH = 44.0;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour; _minute = widget.initial.minute;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() { _hourCtrl.dispose(); _minuteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(fontSize: 15))),
              const Text('选择时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
                child: const Text('确定', style: TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: _buildWheel(24, _hourCtrl, (v) => _hour = v, (i) => '${i.toString().padLeft(2, '0')}时')),
                Container(padding: const EdgeInsets.only(top: _itemH), child: const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300))),
                Expanded(child: _buildWheel(60, _minuteCtrl, (v) => _minute = v, (i) => '${i.toString().padLeft(2, '0')}分')),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildWheel(int count, FixedExtentScrollController ctrl, ValueChanged<int> onChanged, String Function(int) label) {
    return ListWheelScrollView.useDelegate(
      controller: ctrl, itemExtent: _itemH, diameterRatio: 2.0, perspective: 0.004,
      onSelectedItemChanged: onChanged, physics: const FixedExtentScrollPhysics(),
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (_, i) => Center(child: Text(label(i), style: const TextStyle(fontSize: 17))),
        childCount: count,
      ),
    );
  }
}
