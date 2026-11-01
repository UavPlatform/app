import '../../widgets/flow_ui.dart';
import '../../widgets/infinite_list.dart';
import '../waybill/dispatch_order_information.dart';
import '../../widgets/dispatch_notification_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
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
      appBar: AppBar(
        title: const Text('派单大厅'),
        actions: [
          TextButton(
            onPressed: () => context.push('/pilot/dispatch/nearby'),
            child: const Text('附近订单'),
          ),
          const DispatchNotificationEntry(),
          IconButton(
            tooltip: '刷新大厅',
            onPressed: hall.loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: () => context.go('/pilot/jobs'),
            child: const Text('我的接单'),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: FlowHeader(
              title: '选择你的下一单',
              subtitle: '先接者得。接单后查看联系人，按阶段完成交付。',
              icon: Icons.explore_outlined,
            ),
          ),
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
                        onLoadMore: () => ref
                            .read(dispatchPilotHallProvider.notifier)
                            .load(),
                        hasMore: hall.hasNext,
                        loadingMore: hall.loading && hall.items.isNotEmpty,
                        itemCount: hall.items.length,
                        empty: const Center(child: Text('暂无待接订单')),
                        itemBuilder: (context, index) {
                          final offer = hall.items[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 12,
                                children: [
                                  Text(
                                    '${offer.data.fields!['category'] ?? ''} · ${dispatchWeightLabel(offer.data.fields!)} · ${offer.data.fields!['count'] ?? ''} 件',
                                  ),
                                  Text(
                                    '起点：${offer.data.fields!['start.site'] ?? ''}',
                                  ),
                                  Text(
                                    '终点：${offer.data.fields!['end.site'] ?? ''}',
                                  ),
                                  Text(
                                    offer.data.fields!['timeMode'] ==
                                            'scheduled'
                                        ? '预约：${offer.data.fields!['scheduledAt']}'
                                        : '立即出发',
                                  ),
                                  if (offer.data.pilotServiceFee != null)
                                    Text(
                                      '飞手服务费：¥${offer.data.pilotServiceFee!.toStringAsFixed(2)}/单',
                                    ),
                                  const Text(
                                    '预估净收入和建议机型暂未提供。接单后可查看联系人与完整场地信息。',
                                  ),
                                  FilledButton(
                                    onPressed:
                                        _busy ? null : () => _claim(offer),
                                    child: const Text('立即接单'),
                                  ),
                                ],
                              ),
                            ),
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
      title: const Text('我的派单'),
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
              ? const Center(child: Text('暂无当前指派订单'))
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
