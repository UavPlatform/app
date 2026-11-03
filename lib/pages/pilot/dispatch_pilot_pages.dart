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
                    empty: DispatchHallEmptyState(
                      onNearby: () => context.push('/pilot/dispatch/nearby'),
                    ),
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
      title: const Text('我的订单'),
      leading: BackButton(
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/pilot/profile'),
      ),
      actions: [
        IconButton(
          tooltip: '刷新我的接单',
          onPressed: () => ref.invalidate(dispatchPilotOrdersProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
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
          data: (orders) => orders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: const [
                    FlowEmptyState(
                      title: '暂无当前指派订单',
                      icon: Icons.assignment_outlined,
                    ),
                  ],
                )
              : FlowList(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('当前指派和需求方取消的最近50笔；主动退出后订单回到大厅。'),
                    ),
                    for (final order in orders)
                      DispatchOrderCard(
                        order: order,
                        onTap: () => context.push(
                          '/pilot/dispatch/orders/${Uri.encodeComponent(order.id)}',
                        ),
                      ),
                  ],
                ),
        ),
  );
}
