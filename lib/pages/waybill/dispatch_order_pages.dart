import 'dispatch_map_home.dart';
import '../../widgets/dispatch_notification_entry.dart';
import '../../widgets/flow_ui.dart';
import 'dispatch_order_information.dart';
import '../../widgets/dispatch_stage_progress.dart';
import '../../widgets/dispatch_contact_actions.dart';
import 'dispatch_nearby_status.dart';
export '../../widgets/dispatch_stage_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/dispatch_order.dart';
import 'dispatch_fulfillment_pages.dart';
import 'dispatch_price_card.dart';
import 'dispatch_material_panel.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';

class DispatchOrderPage extends ConsumerWidget {
  const DispatchOrderPage({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(dispatchOrderProvider(orderId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('派单运单')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString()),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(dispatchOrderProvider(orderId)),
                  child: const Text('重新查询订单'),
                ),
              ],
            ),
          ),
        ),
        data: (order) => order.awaitingDeposit
            ? DispatchDepositPage(order: order)
            : order.waiting
            ? DispatchWaitingPage(order: order)
            : order.preparing
            ? DispatchPreparingPage(order: order)
            : order.arrived
            ? DispatchArrivedPage(order: order)
            : order.transporting
            ? DispatchTransportPage(order: order)
            : order.confirming
            ? DispatchDeliveryPage(order: order)
            : order.completed
            ? DispatchCompletedPage(order: order)
            : DispatchCancelledPage(order: order),
      );
}

class DispatchDepositPage extends StatelessWidget {
  const DispatchDepositPage({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) => _OrderScaffold(
    order: order,
    title: '待付定金',
    step: 0,
    content: [
      const Text('订单已创建，尚未付款。模拟支付成功后才进入等待接单。'),
      DispatchOrderActions(order: order),
    ],
  );
}

class DispatchWaitingPage extends StatelessWidget {
  const DispatchWaitingPage({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) => _OrderScaffold(
    order: order,
    title: '等待接单',
    step: 1,
    content: [
      const Icon(Icons.radar, size: 72),
      const Text('订单已进入派单大厅，等待飞手接单。'),
      DispatchNearbyStatus(order: order),
      DispatchOrderActions(order: order),
    ],
  );
}

class DispatchPreparingPage extends StatelessWidget {
  const DispatchPreparingPage({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) => _OrderScaffold(
    order: order,
    title: '飞手准备中',
    step: 2,
    content: [
      Text('接单飞手账号：${order.data.assignedPilotId}'),
      const Text('飞手已接单，正在准备前往起点。请保持现场联系人电话畅通。页面会自动查询最新进度。'),
      DispatchOrderActions(order: order),
    ],
  );
}

class DispatchArrivedPage extends StatelessWidget {
  const DispatchArrivedPage({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) => _OrderScaffold(
    order: order,
    title: '飞手已到场',
    step: 3,
    content: [
      Text('接单飞手账号：${order.data.assignedPilotId}'),
      const Text('飞手已提交到场状态，请现场核对货物、包装、吊点和场地。到场状态为飞手本人确认。'),
      Text(
        '货物：${order.data.fields?['category']} · ${order.data.fields?['count']} 件',
      ),
      Text(
        '包装：${order.data.fields?['packaging']}\n吊点：${order.data.fields?['lifting']}',
      ),
      const Text('现场核对后，由飞手确认开始运输；实际飞行操作在 djifly 完成。'),
      DispatchOrderActions(order: order),
    ],
  );
}

class DispatchCancelledPage extends StatelessWidget {
  const DispatchCancelledPage({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) => _OrderScaffold(
    order: order,
    title: '运单已取消',
    content: [
      Text(
        order.data.fundsStatus == 'REFUNDED'
            ? '定金已全额模拟退回，无真实资金变动。'
            : '本单未付款，无需退款。',
      ),
    ],
  );
}

class _OrderScaffold extends ConsumerWidget {
  const _OrderScaffold({
    required this.order,
    required this.title,
    required this.content,
    this.step,
  });
  final DispatchOrder order;
  final String title;
  final List<Widget> content;
  final int? step;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: '刷新订单',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(dispatchOrderProvider(order.id)),
        ),
      ],
    ),
    body: FlowList(
      padding: const EdgeInsets.all(20),
      children: [
        if (step != null) DispatchStageProgress(current: step!),
        FlowHeader(
          title: title,
          subtitle: '运单 ${shortReference(order.id)} · 请按当前阶段继续操作',
          icon: order.waiting
              ? Icons.radar_rounded
              : Icons.local_shipping_outlined,
        ),
        ...content,
        DispatchContactActions(order: order),
        DispatchOrderInformationLink(order: order),
        DispatchPriceCard(quote: order.data.bill?.quote, bill: order.data.bill),
        const FlowNotice('定金使用模拟支付 · 不涉及真实收款', warning: true),
        if (!order.cancelled)
          DispatchMaterialPanel(orderId: order.id, purpose: 'CARGO'),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => context.go('/dispatch/orders'),
          child: const Text('返回派单运单列表'),
        ),
      ],
    ),
  );
}

class DispatchOrderActions extends ConsumerStatefulWidget {
  const DispatchOrderActions({super.key, required this.order});
  final DispatchOrder order;
  @override
  ConsumerState<DispatchOrderActions> createState() =>
      _DispatchOrderActionsState();
}

class _DispatchOrderActionsState extends ConsumerState<DispatchOrderActions> {
  bool _busy = false;
  String? _error;
  Future<void> _act(bool pay) async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pay ? '模拟支付定金' : '取消运单'),
        content: Text(
          pay
              ? '仅模拟支付 ¥${widget.order.data.depositAmount!.toStringAsFixed(2)}，不会真实扣款。'
              : '确认取消本单？已付定金将全额模拟退回，未付款则直接取消。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        scope != ref.read(waybillDraftScopeProvider)) {
      return;
    }
    final api = ref.read(dispatchOrderApiProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (pay) {
        await api.pay(widget.order.id);
      } else {
        await api.cancel(widget.order.id);
      }
      if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
      ref.invalidate(dispatchOrderProvider(widget.order.id));
      ref.invalidate(dispatchOrdersProvider);
    } catch (error) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (widget.order.awaitingDeposit)
        FilledButton(
          onPressed: _busy ? null : () => _act(true),
          child: const Text('模拟支付定金'),
        ),
      OutlinedButton(
        onPressed: _busy ? null : () => _act(false),
        child: Text(_busy ? '处理中…' : '取消运单'),
      ),
    ],
  );
}

class DispatchOrderListPage extends ConsumerWidget {
  const DispatchOrderListPage({super.key, this.tabRoot = false});
  final bool tabRoot;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      backgroundColor:
          tabRoot && Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFFAF8F5)
          : null,
      foregroundColor:
          tabRoot && Theme.of(context).brightness == Brightness.light
          ? const Color(0xFF22252A)
          : null,
      title: Text(tabRoot ? '我的吊运' : '我的派单运单'),
      automaticallyImplyLeading: !tabRoot,
      leading: tabRoot
          ? null
          : BackButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
      actions: [
        if (tabRoot) const DispatchNotificationEntry(),
        if (tabRoot)
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEFECE6),
              foregroundColor: const Color(0xFF444444),
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => context.push('/orders/legacy'),
            child: const Text('旧版订单'),
          ),
        IconButton(
          tooltip: '刷新运单',
          onPressed: () => ref.invalidate(dispatchOrdersProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ref
        .watch(dispatchOrdersProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(dispatchOrdersProvider),
              child: Text('$error\n重新查询'),
            ),
          ),
          data: (orders) => tabRoot
              ? DispatchMapHome(
                  key: ValueKey(ref.watch(waybillDraftScopeProvider)),
                  orders: orders,
                )
              : orders.isEmpty
              ? const _DispatchOrdersEmpty()
              : FlowList(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('最近50笔 · 模拟支付，无真实资金变动'),
                    ),
                    const FlowHeader(
                      title: '我的吊运',
                      subtitle: '订单进度、支付与交付，都在这里。创建新单请点击底部入口。',
                      icon: Icons.inventory_2_outlined,
                    ),
                    for (final order in orders)
                      DispatchOrderCard(
                        order: order,
                        onTap: () => context.push(
                          '/dispatch/orders/${Uri.encodeComponent(order.id)}',
                        ),
                      ),
                  ],
                ),
        ),
  );
}

class _DispatchOrdersEmpty extends StatelessWidget {
  const _DispatchOrdersEmpty();
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 22),
          Text('暂无派单运单', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            '创建第一张吊运订单，\n之后可以在首页查看进度、联系飞手和确认收货。',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('create-first-dispatch'),
            onPressed: () => context.push('/waybill/new'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('创建第一单'),
          ),
        ],
      ),
    ),
  );
}
