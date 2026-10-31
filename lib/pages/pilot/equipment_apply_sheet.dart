import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/generated/openapi_models.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/waybill_draft_provider.dart';

Future<void> showEquipmentApplySheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const EquipmentApplySheet(),
  );
}

class EquipmentApplySheet extends ConsumerStatefulWidget {
  const EquipmentApplySheet({super.key});
  @override
  ConsumerState<EquipmentApplySheet> createState() =>
      _EquipmentApplySheetState();
}

class _EquipmentApplySheetState extends ConsumerState<EquipmentApplySheet> {
  int? _modelId;
  String? _orderId;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy) return;
    final modelId = _modelId;
    if (modelId == null) {
      setState(() => _error = '请先选择有在库飞机的机型');
      return;
    }
    final scope = ref.read(waybillDraftScopeProvider);
    if (scope == null) return;

    final current = await ref.read(equipmentCurrentProvider.future);
    final hasLoan = (current.items ?? const []).isNotEmpty;
    if (!mounted) return;
    if (hasLoan) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('已有已借出飞机'),
          content: const Text(
            '默认一人同时只借一台。建议先归还后再申请；仍可提交，由管理员决定是否特批第二台。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('先去归还'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('仍要申请'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    bool alive() => mounted && scope == ref.read(waybillDraftScopeProvider);
    try {
      final store = ref.read(equipmentRequestStoreProvider);
      final subject = 'model-$modelId';
      final key = await store.requestKey(scope, subject);
      if (!alive()) return;
      final result = await ref.read(equipmentApiProvider).apply(
            aircraftModelId: modelId,
            requestKey: key,
            orderId: _orderId,
          );
      if (!alive()) return;
      if (result.status == 'PENDING' || result.status == 'APPROVED') {
        await store.clear(scope, subject, key);
      }
      if (!alive()) return;
      ref.invalidate(equipmentCurrentProvider);
      ref.invalidate(equipmentBorrowsProvider);
      ref.invalidate(equipmentModelStockProvider);
      final warn = result.alreadyHasActiveLoan == true;
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      if (warn) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('已提交；你手头已有已借出飞机，等待管理员是否特批。')),
        );
      }
    } catch (error) {
      if (alive()) {
        setState(
          () => _error = '$error\n结果未确认时请刷新申请列表；重试会沿用本次申请标识。',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _choice({
    required String title,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      dense: true,
      enabled: onTap != null,
      title: Text(title),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = ref.watch(equipmentModelStockProvider);
    final orders = ref.watch(dispatchPilotOrdersProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding:
          EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('发起借机申请', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('只选机型，不选机身号；订单可选关联。管理员审批时指定具体飞机。'),
            const SizedBox(height: 16),
            Text('机型', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            stock.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => TextButton(
                onPressed: () => ref.invalidate(equipmentModelStockProvider),
                child: Text('$e\n重新查询在库'),
              ),
              data: (vo) {
                final items = (vo.items ?? const <ApiItem>[])
                    .where((i) => (i.inStockCount ?? 0) > 0)
                    .toList();
                if (items.isEmpty) {
                  return const Text('当前没有可申请的在库机型。');
                }
                return Column(
                  children: [
                    for (final item in items)
                      _choice(
                        title: '${item.modelName}（在库 ${item.inStockCount}）',
                        selected: _modelId == item.aircraftModelId,
                        onTap: _busy
                            ? null
                            : () => setState(() {
                                  _modelId = item.aircraftModelId;
                                  _error = null;
                                }),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text('关联订单（可选）', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            orders.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                final active = list
                    .where((o) => !o.completed)
                    .toList(growable: false);
                return Column(
                  children: [
                    _choice(
                      title: '不关联订单',
                      selected: _orderId == null,
                      onTap: _busy
                          ? null
                          : () => setState(() => _orderId = null),
                    ),
                    for (final DispatchOrder order in active)
                      _choice(
                        title: order.id,
                        selected: _orderId == order.id,
                        onTap: _busy
                            ? null
                            : () => setState(() => _orderId = order.id),
                      ),
                  ],
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? '提交中…' : '提交申请'),
            ),
          ],
        ),
      ),
    );
  }
}
