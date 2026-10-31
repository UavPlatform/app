import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/generated/openapi_models.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../theme/app_colors.dart';
import 'equipment_apply_sheet.dart';
import 'equipment_borrow_action.dart';

String equipmentStatusLabel(String? status) {
  switch (status) {
    case 'PENDING':
      return '待审批';
    case 'APPROVED':
      return '已借出';
    case 'REJECTED':
      return '已驳回';
    case 'RETURNED':
      return '已归还';
    default:
      return status ?? '未知';
  }
}

/// REQ-PILOT-EXEC-005 / DS-APP-003：「无人机」一级页。
class EquipmentBorrowPage extends ConsumerWidget {
  const EquipmentBorrowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(waybillDraftScopeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('无人机'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(equipmentCurrentProvider);
              ref.invalidate(equipmentBorrowsProvider);
              ref.invalidate(equipmentModelStockProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEquipmentApplySheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('发起申请'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(equipmentCurrentProvider);
          ref.invalidate(equipmentBorrowsProvider);
          try {
            await Future.wait([
              ref.read(equipmentCurrentProvider.future),
              ref.read(equipmentBorrowsProvider(0).future),
            ]);
          } catch (_) {
            /* providers render errors */
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            Text(
              '当前借着的飞机',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _CurrentSection(key: ValueKey('current:$scope')),
            const SizedBox(height: 24),
            Text(
              '我的申请',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ApplicationsSection(key: ValueKey('apps:$scope')),
          ],
        ),
      ),
    );
  }
}

class _CurrentSection extends ConsumerWidget {
  const _CurrentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(equipmentCurrentProvider).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => TextButton(
        onPressed: () => ref.invalidate(equipmentCurrentProvider),
        child: Text('$e\n重新查询'),
      ),
      data: (page) {
        final items = page.items ?? const <ApiDroneBorrowVO>[];
        if (items.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('当前没有已借出的飞机。需要时点右下角发起申请。'),
            ),
          );
        }
        return Column(
          children: [
            for (final loan in items) _LoanCard(loan: loan, current: true),
          ],
        );
      },
    );
  }
}

class _ApplicationsSection extends ConsumerStatefulWidget {
  const _ApplicationsSection({super.key});
  @override
  ConsumerState<_ApplicationsSection> createState() =>
      _ApplicationsSectionState();
}

class _ApplicationsSectionState extends ConsumerState<_ApplicationsSection> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return ref.watch(equipmentBorrowsProvider(_page)).when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => TextButton(
        onPressed: () => ref.invalidate(equipmentBorrowsProvider(_page)),
        child: Text('$e\n重新查询'),
      ),
      data: (page) {
        final items = page.items ?? const <ApiDroneBorrowVO>[];
        return Column(
          children: [
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无申请记录'),
                ),
              ),
            for (final loan in items) _LoanCard(loan: loan),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _page == 0
                      ? null
                      : () => setState(() => _page--),
                  child: const Text('上一页'),
                ),
                Text('第 ${_page + 1} 页'),
                TextButton(
                  onPressed: page.hasNext == true
                      ? () => setState(() => _page++)
                      : null,
                  child: const Text('下一页'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, this.current = false});
  final ApiDroneBorrowVO loan;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final drone = loan.drone;
    final status = loan.status;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loan.modelName ?? '未知机型',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    equipmentStatusLabel(status),
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            if (drone != null) ...[
              const SizedBox(height: 4),
              Text('机身号：${drone.serialNumber}'),
              Text('机场：${drone.airportName ?? '未知'}'),
            ],
            if (loan.orderId != null && loan.orderId!.isNotEmpty)
              Text('关联订单：${loan.orderId}'),
            if (loan.appliedAt != null) Text('申请时间：${loan.appliedAt}'),
            if (loan.borrowedAt != null) Text('借出时间：${loan.borrowedAt}'),
            if (loan.returnedAt != null) Text('归还时间：${loan.returnedAt}'),
            if (status == 'REJECTED') ...[
              const SizedBox(height: 8),
              Text(
                '驳回原因：${(loan.rejectReason ?? '').isEmpty ? '未填写' : loan.rejectReason}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (current || status == 'APPROVED') ...[
              const SizedBox(height: 8),
              EquipmentReturnAction(borrowId: loan.borrowId!),
            ],
          ],
        ),
      ),
    );
  }
}
