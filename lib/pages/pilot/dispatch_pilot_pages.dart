import '../../widgets/flow_ui.dart';
import '../../widgets/infinite_list.dart';
import '../waybill/dispatch_order_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import 'dispatch_hall_ui.dart';
export 'dispatch_pilot_order_page.dart';

class DispatchPilotHallPage extends ConsumerStatefulWidget {
  const DispatchPilotHallPage({super.key});
  @override
  ConsumerState<DispatchPilotHallPage> createState() =>
      _DispatchPilotHallPageState();
}

class _DispatchPilotHallPageState extends ConsumerState<DispatchPilotHallPage> {
  bool _busy = false;
  String? _error;
  Future<void> _claim(DispatchOffer offer) async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    final api = ref.read(dispatchOrderApiProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await api.claim(offer.id, offer.data.offerRevision!);
      if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
      ref.invalidate(dispatchPilotHallProvider);
      ref.invalidate(dispatchPilotOrdersProvider);
      context.push('/pilot/dispatch/orders/${Uri.encodeComponent(order.id)}');
    } catch (error) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() => _error = '$error\n结果未确认时，请查看“我的接单”后再试。');
        ref.invalidate(dispatchPilotHallProvider);
        ref.invalidate(dispatchPilotOrdersProvider);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() =>
      ref.read(dispatchPilotHallProvider.notifier).load(refresh: true);

  @override
  Widget build(BuildContext context) {
    final hall = ref.watch(dispatchPilotHallProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '派单大厅',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () => context.push('/pilot/dispatch/nearby'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE8F3FF),
                foregroundColor: const Color(0xFF1D6FE9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.near_me_outlined, size: 15),
                  SizedBox(width: 4),
                  Text(
                    '附近订单',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const DispatchHallWorkbench(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: hall.isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : hall.error != null && hall.items.isEmpty
                ? Center(
                    child: TextButton(
                      onPressed: _refresh,
                      child: Text('${hall.error}\n重新查询大厅'),
                    ),
                  )
                : InfiniteList(
                    onRefresh: _refresh,
                    onLoadMore: () =>
                        ref.read(dispatchPilotHallProvider.notifier).load(),
                    hasMore: hall.hasNext,
                    loadingMore: hall.loading && hall.items.isNotEmpty,
                    itemCount: hall.items.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    separatorHeight: 0,
                    empty: DispatchHallEmptyState(onRefresh: _refresh),
                    itemBuilder: (context, index) {
                      final offer = hall.items[index];
                      return DispatchHallOfferCard(
                        offer: offer,
                        onClaim: _busy ? null : () => _claim(offer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DispatchPilotJobsPage extends ConsumerWidget {
  const DispatchPilotJobsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('接单记录'),
      leading: BackButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/pilot/profile'),
      ),
    ),
    body: ref
        .watch(dispatchPilotOrdersProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(dispatchPilotOrdersProvider),
              child: Text('$error\n重新查询'),
            ),
          ),
          data: (orders) {
            final pending = orders.where(
              (order) => !order.completed && !order.cancelled,
            );
            final ended = orders.where(
              (order) => order.completed || order.cancelled,
            );
            return FlowList(
              children: [
                if (orders.isEmpty) ...[
                  const FlowEmptyState(
                    title: '暂无当前指派订单',
                    icon: Icons.assignment_outlined,
                  ),
                  Center(
                    child: FilledButton(
                      onPressed: () => context.go('/pilot/home'),
                      child: const Text('返回接单大厅'),
                    ),
                  ),
                ] else
                  for (final (label, items) in [
                    ('待执行', pending),
                    ('已结束／已取消', ended),
                  ]) ...[
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
                    if (items.isEmpty) const Text('暂无记录'),
                    for (final order in items)
                      DispatchOrderCard(
                        order: order,
                        onTap: () => context.push(
                          '/pilot/dispatch/orders/${Uri.encodeComponent(order.id)}',
                        ),
                      ),
                  ],
              ],
            );
          },
        ),
  );
}
