// 选定飞手下单弹窗（TASK-APP-004 / ADR-0003 决定 2、3、4）：
//   展示锁定的系统报价（只读）→ 选择约定作业时间（scheduledTime）→
//   调用 POST /task/{taskNum}/select-rider（只发 applicationId + scheduledTime，
//   金额由服务端锁定为该应征 quotedAmount，本弹窗不存在任何价格输入控件）。
// 未选择约定作业时间时「确认下单」禁用（服务端同样要求必填）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task_application_vo.dart';
import '../../../providers/task_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/scroll_pickers.dart';

/// 选定飞手下单：返回 true 表示 select-rider 已成功（调用方随后刷新并进入支付）。
Future<bool?> showSelectRiderDialog(
  BuildContext context, {
  required String taskNum,
  required TaskApplicationVo application,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        SelectRiderDialog(taskNum: taskNum, application: application),
  );
}

class SelectRiderDialog extends ConsumerStatefulWidget {
  final String taskNum;
  final TaskApplicationVo application;

  const SelectRiderDialog({
    super.key,
    required this.taskNum,
    required this.application,
  });

  @override
  ConsumerState<SelectRiderDialog> createState() => _SelectRiderDialogState();
}

class _SelectRiderDialogState extends ConsumerState<SelectRiderDialog> {
  DateTime? _date;
  TimeOfDay? _time;
  bool _submitting = false;
  String? _error;

  bool get _timePicked => _date != null && _time != null;

  /// 约定作业时间契约格式（yyyy-MM-dd HH:mm:ss）。
  String get _scheduledTime {
    final date = _date!;
    final time = _time!;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(time.hour)}:${two(time.minute)}:00';
  }

  Future<void> _pickDate() async {
    final picked = await showScrollDatePicker(context, initial: _date);
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showScrollTimePicker(context, initial: _time);
    if (picked != null && mounted) {
      setState(() {
        _time = picked;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_timePicked || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(taskApiProvider)
        .selectRider(
          taskNum: widget.taskNum,
          applicationId: widget.application.applicationId!,
          scheduledTime: _scheduledTime,
        );
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _submitting = false;
        _error = result.message ?? '下单失败，请稍后重试';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    return AlertDialog(
      title: const Text('选定飞手下单'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('飞手', app.displayName),
            _row('机型', app.aircraftLabel),
            _row('系统报价', '${app.quotedAmountText}（平台计价）'),
            const SizedBox(height: 4),
            const Divider(height: 16),
            const Text(
              '约定作业时间',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _pickDate,
                    child: Text(
                      _date == null
                          ? '选择日期'
                          : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _pickTime,
                    child: Text(
                      _time == null
                          ? '选择时间'
                          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _timePicked ? '将于 $_scheduledTime 开始作业' : '未选择约定作业时间，无法提交下单',
              style: TextStyle(
                fontSize: 12,
                color: _timePicked
                    ? AppColors.onSurfaceVariant
                    : AppColors.error,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _timePicked && !_submitting ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC45100),
            foregroundColor: Colors.white,
            minimumSize: const Size(120, 48),
          ),
          child: Text(_submitting ? '下单中…' : '确认下单'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
