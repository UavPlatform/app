import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/waybill_draft_provider.dart';

class EquipmentBorrowAction extends ConsumerStatefulWidget {
  const EquipmentBorrowAction({
    super.key,
    required this.droneId,
    this.borrowId,
  });
  final String droneId;
  final String? borrowId;
  @override
  ConsumerState<EquipmentBorrowAction> createState() =>
      _EquipmentBorrowActionState();
}

class _EquipmentBorrowActionState extends ConsumerState<EquipmentBorrowAction> {
  bool _busy = false;
  String? _error;
  Future<void> _act() async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    if (scope == null) return;
    final returning = widget.borrowId != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(returning ? '登记归还' : '登记借用'),
        content: Text(
          returning
              ? '请确认已将这架无人机交还服务商，再提交归还登记。'
              : '请与服务商现场核对机身号并确认交接，再登记借用。本次不收费、不收押金、不关联订单。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认登记'),
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
      final api = ref.read(equipmentApiProvider);
      final store = ref.read(equipmentRequestStoreProvider);
      if (returning) {
        final previous = store.saved(scope, widget.droneId);
        await api.giveBack(widget.borrowId!);
        if (!current()) return;
        if (previous != null) {
          await store.clear(scope, widget.droneId, previous);
        }
      } else {
        final key = await store.requestKey(scope, widget.droneId);
        if (!current()) return;
        final result = await api.borrow(widget.droneId, key);
        if (!current()) return;
        if (result.returnedAt != null) {
          await store.clear(scope, widget.droneId, key);
          if (current()) setState(() => _error = '上次借用已经归还，请再次确认后登记新的借用');
        }
      }
      if (!current()) return;
      ref.invalidate(equipmentCatalogProvider);
      ref.invalidate(equipmentBorrowsProvider);
    } catch (error) {
      if (current()) {
        setState(() => _error = '$error\n结果未确认时请刷新“我的借还”，重试会沿用本次登记标识。');
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
        child: Text(
          _busy
              ? '登记中…'
              : widget.borrowId == null
              ? '登记借用'
              : '登记归还',
        ),
      ),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}
