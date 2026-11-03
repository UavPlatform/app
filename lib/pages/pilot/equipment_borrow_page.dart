import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/generated/openapi_models.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../widgets/infinite_list.dart';
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
    final borrows = ref.watch(equipmentBorrowsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '无人机',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(equipmentCurrentProvider);
              ref.invalidate(equipmentBorrowsProvider);
              ref.invalidate(equipmentModelStockProvider);
            },
            icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF333333)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D6FE9),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onPressed: () => showEquipmentApplySheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('发起申请'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(equipmentCurrentProvider);
          try {
            await Future.wait([
              ref.read(equipmentCurrentProvider.future),
              ref.read(equipmentBorrowsProvider.notifier).load(refresh: true),
            ]);
          } catch (_) {
            /* providers render errors */
          }
        },
        child: LoadMoreListener(
          canLoadMore: borrows.hasNext && !borrows.loading,
          onLoadMore: () => ref.read(equipmentBorrowsProvider.notifier).load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Text(
                  '当前执飞设备',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2329),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _CurrentSection(key: ValueKey('current:$scope')),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: Text(
                  '我的申请',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2329),
                  ),
                ),
              ),
              _ApplicationsSection(key: ValueKey('apps:$scope')),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdleEquipmentCard extends StatelessWidget {
  const _IdleEquipmentCard({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final applyButton = FilledButton(
      onPressed: onApply,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1D6FE9),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: const Text('立即申请'),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(13) > 16;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.flight_rounded,
                      size: 28,
                      color: Color(0xFF1D6FE9),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '暂未借用设备',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2329),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '空闲中 · 执飞前请先申请调配',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[const SizedBox(width: 12), applyButton],
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: applyButton),
              ],
              const Divider(height: 24, color: Color(0xFFF0F2F5)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Expanded(child: _ApplyStep('① 提交申请')),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Color(0xFFCCCCCC),
                    ),
                    Expanded(child: _ApplyStep('② 后台审批')),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: Color(0xFFCCCCCC),
                    ),
                    Expanded(child: _ApplyStep('③ 领用执飞')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplyStep extends StatelessWidget {
  const _ApplyStep(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
  );
}

class _CurrentSection extends ConsumerWidget {
  const _CurrentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(equipmentCurrentProvider)
        .when(
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
              return _IdleEquipmentCard(
                onApply: () => showEquipmentApplySheet(context, ref),
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

class _ApplicationsSection extends ConsumerWidget {
  const _ApplicationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(equipmentBorrowsProvider);
    if (page.isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (page.error != null && page.items.isEmpty) {
      return TextButton(
        onPressed: () =>
            ref.read(equipmentBorrowsProvider.notifier).load(refresh: true),
        child: Text('${page.error}\n重新查询'),
      );
    }
    return Column(
      children: [
        if (page.items.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 30,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '暂无申请记录',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '您的无人机领用与归还记录将显示在这里',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        for (final loan in page.items) _LoanCard(loan: loan),
        if (page.items.isNotEmpty || page.loading || page.hasNext)
          InfiniteListFooter(
            loading: page.loading && page.items.isNotEmpty,
            hasMore: page.hasNext,
            showEndMessage: page.items.isNotEmpty && !page.hasNext,
          ),
      ],
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
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 13,
        height: 1.5,
        color: Color(0xFF666666),
      ),
      child: Container(
        margin: current
            ? const EdgeInsets.only(bottom: 6)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(current ? 16 : 12),
        ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2329),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'APPROVED'
                          ? const Color(0xFFE6F8F0)
                          : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      equipmentStatusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: status == 'APPROVED'
                            ? const Color(0xFF00B578)
                            : const Color(0xFF666666),
                      ),
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
      ),
    );
  }
}
