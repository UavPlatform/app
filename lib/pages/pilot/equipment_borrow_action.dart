import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/waybill_draft_provider.dart';

/// 已借出飞机的主动归还（归还不需审批）。
class EquipmentReturnAction extends ConsumerStatefulWidget {
  const EquipmentReturnAction({super.key, required this.borrowId});
  final String borrowId;
  @override
  ConsumerState<EquipmentReturnAction> createState() =>
      _EquipmentReturnActionState();
}

class _EquipmentReturnActionState extends ConsumerState<EquipmentReturnAction> {
  bool _busy = false;
  String? _error;

  Future<void> _act() async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    if (scope == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认归还'),
        content: const Text(
          '归还立即生效，不需要管理员再批。请确认已将飞机交还现场。换机请先还再借。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认归还'),
          ),
        ],
      ),
    );
    bool current() => mounted && scope == ref.read(waybillDraftScopeProvider);
    if (confirmed != true || !current()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(equipmentApiProvider).giveBack(widget.borrowId);
      if (!current()) return;
      ref.invalidate(equipmentCurrentProvider);
      ref.invalidate(equipmentBorrowsProvider);
      ref.invalidate(equipmentModelStockProvider);
    } catch (error) {
      if (current()) {
        setState(() => _error = '$error\n结果未确认时请下拉刷新后再试。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: _busy ? null : _act,
            child: Text(_busy ? '归还中…' : '归还'),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      );
}
