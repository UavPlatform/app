import '../../widgets/flow_ui.dart';
import '../waybill/dispatch_order_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/dispatch_order.dart';
import '../waybill/dispatch_fulfillment_pages.dart';
import '../waybill/dispatch_price_card.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../services/phone_dialer.dart';
import '../../widgets/dispatch_contact_actions.dart';
import '../waybill/dispatch_order_pages.dart' show DispatchStageProgress;

class DispatchPilotOrderPage extends ConsumerWidget {
  const DispatchPilotOrderPage({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(dispatchPilotOrderProvider(orderId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('派单详情')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString()),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(dispatchPilotOrderProvider(orderId)),
                  child: const Text('重新查询'),
                ),
                TextButton(
                  onPressed: () => context.go('/pilot/jobs'),
                  child: const Text('返回我的接单'),
                ),
              ],
            ),
          ),
        ),
        data: (order) => order.preparing
            ? DispatchPilotPreparationPage(order: order)
            : order.arrived
            ? DispatchPilotArrivalPage(order: order)
            : order.transporting
            ? DispatchTransportPage(order: order, pilot: true)
            : order.confirming
            ? DispatchDeliveryPage(order: order, pilot: true)
            : order.completed
            ? DispatchCompletedPage(order: order, pilot: true)
            : _PilotOrderShell(order: order, title: '需求方已取消', step: null),
      );
}

class DispatchPilotPreparationPage extends StatelessWidget {
  const DispatchPilotPreparationPage({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) =>
      _PilotOrderShell(order: order, title: '准备前往起点', step: 2);
}

class DispatchPilotArrivalPage extends StatelessWidget {
  const DispatchPilotArrivalPage({super.key, required this.order});
  final DispatchOrder order;
  @override
  Widget build(BuildContext context) =>
      _PilotOrderShell(order: order, title: '已到场 · 核对货物', step: 3);
}

class _PilotOrderShell extends ConsumerWidget {
  const _PilotOrderShell({
    required this.order,
    required this.title,
    required this.step,
  });
  final DispatchOrder order;
  final String title;
  final int? step;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = order.data.fields ?? {};
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: '刷新派单',
            onPressed: () =>
                ref.invalidate(dispatchPilotOrderProvider(order.id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FlowList(
        padding: const EdgeInsets.all(16),
        children: [
          if (step != null) DispatchStageProgress(current: step!),
          FlowHeader(title: title, subtitle: '核对现场资料，按阶段继续执行。'),
          DispatchOrderInformationLink(order: order, pilot: true),
          DispatchPriceCard(quote: order.data.bill?.quote),
          DispatchContactActions(order: order, pilot: true),
          const Text('定金收退款使用模拟通道，环境评估为演示样例。请以实际现场核对结果为准。'),
          if (order.cancelled) const Text('需求方已取消，请停止继续执行。定金已按当前模拟支付通道处理。'),
          for (final side in ['start', 'end'])
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Text(
                      side == 'start' ? '起点' : '终点',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${fields['$side.site'] ?? ''} · ${fields['$side.lat']}, ${fields['$side.lng']}',
                    ),
                    Text(
                      fields['$side.landing'] == 'yes'
                          ? '可降落'
                          : '绞盘高度 ${fields['$side.winchMin']}–${fields['$side.winchMax']} m',
                    ),
                    Text(
                      '联系人：${fields['$side.contact'] ?? ''} · ${fields['$side.phone'] ?? ''}',
                    ),
                    if ((fields['$side.notes'] ?? '').toString().isNotEmpty)
                      Text(
                        '备注：${fields['$side.notes']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (!order.cancelled)
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await ref
                              .read(phoneDialerProvider)
                              .dial(fields['$side.phone'].toString());
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('无法打开拨号，请手动拨打上述电话')),
                            );
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('拨打联系人'),
                      ),
                  ],
                ),
              ),
            ),
          Text(
            '货物核对：${fields['category']} · ${dispatchWeightLabel(fields)} · ${fields['count']} 件',
          ),
          Text(
            '尺寸：${fields['length']} × ${fields['width']} × ${fields['height']} cm',
          ),
          Text('包装：${fields['packaging']}\n吊点：${fields['lifting']}'),
          if (!order.cancelled) ...[
            const Text('执飞引导：联系现场人员，前往起点并核对货物、吊点及场地。实际连机与飞行操作继续在 djifly 完成。'),
            if (order.arrived)
              const Text('请核对货物和场地后确认开始运输。此按钮只记录业务状态，实际起飞由 djifly 操作。'),
            _PilotOrderActions(order: order),
          ],
          OutlinedButton(
            onPressed: () => context.go('/pilot/jobs'),
            child: const Text('返回我的接单'),
          ),
        ],
      ),
    );
  }
}

class _PilotOrderActions extends ConsumerStatefulWidget {
  const _PilotOrderActions({required this.order});
  final DispatchOrder order;
  @override
  ConsumerState<_PilotOrderActions> createState() => _PilotOrderActionsState();
}

class _PilotOrderActionsState extends ConsumerState<_PilotOrderActions> {
  bool _busy = false;
  String? _error;
  Future<void> _act(bool release, {bool start = false}) async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    final version = widget.order.data.assignmentVersion;
    if (version == null || version < 1) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          start
              ? '确认开始运输'
              : release
              ? '取消接单'
              : '确认已到场',
        ),
        content: Text(
          start
              ? '确认现场核对已完成并开始运输？此操作不会发送无人机起飞指令。'
              : release
              ? '订单将重新回到大厅，定金保持已支付。确认退出本次接单？'
              : '确认你已到达运单起点？此操作由你确认，不代表系统核验了GPS位置。',
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
      if (start) {
        await api.startTransport(widget.order.id, version);
      } else if (release) {
        await api.release(widget.order.id, version);
      } else {
        await api.arrive(widget.order.id, version);
      }
      if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
      ref.invalidate(dispatchPilotOrdersProvider);
      ref.invalidate(dispatchPilotHallProvider);
      ref.invalidate(dispatchPilotOrderProvider(widget.order.id));
      if (release) context.go('/pilot/jobs');
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
      if (widget.order.preparing)
        FilledButton(
          onPressed: _busy ? null : () => _act(false),
          child: const Text('我已到场'),
        ),
      if (widget.order.arrived)
        FilledButton(
          onPressed: _busy ? null : () => _act(false, start: true),
          child: const Text('确认开始运输'),
        ),
      OutlinedButton(
        onPressed: _busy ? null : () => _act(true),
        child: Text(_busy ? '处理中…' : '取消接单，重新派单'),
      ),
    ],
  );
}
