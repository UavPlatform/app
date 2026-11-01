import 'dispatch_detail_surface.dart';
import 'dispatch_order_status_card.dart';
import '../../widgets/flow_ui.dart';
import 'dispatch_order_information.dart';
import '../../widgets/dispatch_contact_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../providers/equipment_provider.dart';
import 'dispatch_material_panel.dart';
import 'dispatch_flight_panel.dart';
import 'package:latlong2/latlong.dart';
import 'dispatch_price_card.dart';

class DispatchTransportPage extends StatelessWidget {
  const DispatchTransportPage({
    super.key,
    required this.order,
    this.pilot = false,
  });
  final DispatchOrder order;
  final bool pilot;
  @override
  Widget build(BuildContext context) =>
      DispatchFulfillmentShell(order: order, pilot: pilot, phase: '运输中');
}

class DispatchDeliveryPage extends StatelessWidget {
  const DispatchDeliveryPage({
    super.key,
    required this.order,
    this.pilot = false,
  });
  final DispatchOrder order;
  final bool pilot;
  @override
  Widget build(BuildContext context) =>
      DispatchFulfillmentShell(order: order, pilot: pilot, phase: '送达双确认');
}

class DispatchCompletedPage extends StatelessWidget {
  const DispatchCompletedPage({
    super.key,
    required this.order,
    this.pilot = false,
  });
  final DispatchOrder order;
  final bool pilot;
  @override
  Widget build(BuildContext context) =>
      DispatchFulfillmentShell(order: order, pilot: pilot, phase: '已结单');
}

class DispatchFulfillmentShell extends ConsumerStatefulWidget {
  const DispatchFulfillmentShell({
    super.key,
    required this.order,
    required this.pilot,
    required this.phase,
  });
  final DispatchOrder order;
  final bool pilot;
  final String phase;
  @override
  ConsumerState<DispatchFulfillmentShell> createState() =>
      _DispatchFulfillmentShellState();
}

class _DispatchFulfillmentShellState
    extends ConsumerState<DispatchFulfillmentShell> {
  bool _busy = false;
  String? _error;
  List<String> _materials = [];
  int _score = 5;
  final _comment = TextEditingController();
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _act(String action) async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(
          action == '模拟支付尾款'
              ? '本次仅模拟结算，不会真实扣款。'
              : action == '取消运单'
              ? '定金将全额模拟退回。取消业务订单不会自动停止实际飞行，请与飞手联系处置。'
              : action == '提交评价'
              ? '评价提交后不能修改。确认提交？'
              : '请确认现场情况与所选凭证真实。',
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(dispatchOrderApiProvider);
      final order = widget.order;
      switch (action) {
        case '确认送达':
          await api.deliver(
            order.id,
            order.data.assignmentVersion!,
            _materials,
          );
        case '确认收货并结单':
          await api.receipt(order.id, _materials);
        case '模拟支付尾款':
          await api.settle(order.id);
        case '提交评价':
          await api.review(order.id, _score, _comment.text.trim());
        case '取消运单':
          await api.cancel(order.id);
      }
      if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
      ref.invalidate(dispatchOrderProvider(order.id));
      ref.invalidate(dispatchPilotOrderProvider(order.id));
      ref.invalidate(dispatchOrdersProvider);
      ref.invalidate(dispatchPilotOrdersProvider);
      // REQ-PILOT-EXEC-005：飞手确认送达（结单链路）后，若手里有已借出飞机则询问是否继续用。
      if (widget.pilot && action == '确认送达') {
        await _askKeepBorrowedDrone(scope);
      }
    } catch (error) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> _askKeepBorrowedDrone(String? scope) async {
    try {
      final current = await ref.read(equipmentApiProvider).current();
      final loans = current.items ?? const [];
      if (!mounted || scope != ref.read(waybillDraftScopeProvider) || loans.isEmpty) {
        return;
      }
      for (final loan in loans) {
        if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
        final drone = loan.drone;
        final label = [
          loan.modelName ?? '飞机',
          if (drone?.serialNumber != null) drone!.serialNumber!,
        ].join(' · ');
        final keep = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('这架飞机还要继续用吗？'),
            content: Text(
              '订单已确认送达。当前借着：$label。\n继续则保留借用；不需要则立即归还（无需审批）。换机请先还再借。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('不需要，归还'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('继续用'),
              ),
            ],
          ),
        );
        if (keep == true || !mounted || scope != ref.read(waybillDraftScopeProvider)) {
          continue;
        }
        if (keep == false && loan.borrowId != null) {
          await ref.read(equipmentApiProvider).giveBack(loan.borrowId!);
          if (!mounted || scope != ref.read(waybillDraftScopeProvider)) return;
          ref.invalidate(equipmentCurrentProvider);
          ref.invalidate(equipmentBorrowsProvider);
          ref.invalidate(equipmentModelStockProvider);
        }
      }
    } catch (error) {
      if (mounted && scope == ref.read(waybillDraftScopeProvider)) {
        setState(() => _error = '送达已确认，但查询/归还飞机失败：$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final bill = order.data.bill;
    final endLat = double.tryParse(order.data.fields?['end.lat'] ?? '');
    final endLng = double.tryParse(order.data.fields?['end.lng'] ?? '');
    final destination =
        endLat != null && endLng != null && endLat.isFinite && endLng.isFinite
        ? LatLng(endLat, endLng)
        : null;
    final purpose = widget.pilot && order.transporting
        ? 'PILOT_DELIVERY'
        : !widget.pilot && order.confirming
        ? 'SHIPPER_RECEIPT'
        : null;
    return Theme(
      data: dispatchDetailTheme(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('订单详情'),
          actions: [
            IconButton(
              tooltip: '刷新订单',
              onPressed: () {
                ref.invalidate(dispatchOrderProvider(order.id));
                ref.invalidate(dispatchPilotOrderProvider(order.id));
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DispatchContactActions(
              order: order,
              pilot: widget.pilot,
              chatOnly: true,
            ),
          ),
        ),
        body: FlowList(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          spacing: 12,
          children: [
            DispatchOrderStatusCard(
              order: order,
              title: order.stageLabel,
              step: order.transporting
                  ? 4
                  : order.confirming
                  ? 5
                  : 6,
            ),
            DispatchOrderInformationLink(order: order, pilot: widget.pilot),
            DispatchPriceCard(
              quote: bill?.quote,
              bill: bill,
              orderId: order.id,
              pilot: widget.pilot,
            ),
            if (widget.pilot && !order.completed)
              DispatchContactActions(
                order: order,
                pilot: widget.pilot,
                hideChat: true,
              ),
            if (order.transporting) ...[
              if (widget.pilot) const Text('请在飞行端完成连机与飞行操作。'),
              DispatchFlightPanel(
                key: ValueKey(order.id),
                orderId: order.id,
                destination: destination,
              ),
              if (!widget.pilot) const Text('送达后将通知你确认收货。'),
            ],
            if (order.confirming)
              Text(
                widget.pilot
                    ? '送达凭证已提交，等待需求方上传收货凭证并确认。'
                    : '请查看飞手送达凭证，上传本次收货凭证后确认收货。',
              ),
            DispatchMaterialPanel(
              key: ValueKey('${order.id}:$purpose'),
              orderId: order.id,
              purpose: purpose,
              onSelected: purpose == null
                  ? null
                  : (ids) => setState(() => _materials = ids),
            ),
            if (purpose != null)
              FilledButton(
                onPressed: _busy || _materials.isEmpty
                    ? null
                    : () => _act(widget.pilot ? '确认送达' : '确认收货并结单'),
                child: Text(widget.pilot ? '确认送达' : '确认收货并结单'),
              ),
            if (!widget.pilot && !order.completed)
              OutlinedButton(
                onPressed: _busy ? null : () => _act('取消运单'),
                child: const Text('取消运单'),
              ),
            if (order.completed) ...[
              Text(
                order.data.fundsStatus == 'BALANCE_DUE' ? '已确认收货，待支付尾款' : '已结算',
              ),
              if (!widget.pilot && order.data.fundsStatus == 'BALANCE_DUE')
                FilledButton(
                  onPressed: _busy ? null : () => _act('模拟支付尾款'),
                  child: const Text('模拟支付尾款'),
                ),
              if (bill?.reviewScore != null)
                Text('评价：${bill!.reviewScore} 分\n${bill.reviewComment ?? ''}')
              else if (!widget.pilot &&
                  order.data.fundsStatus == 'SETTLED') ...[
                DropdownButton<int>(
                  value: _score,
                  items: [
                    for (var i = 1; i <= 5; i++)
                      DropdownMenuItem(value: i, child: Text('$i 分')),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _score = value!),
                ),
                TextField(
                  controller: _comment,
                  maxLength: 500,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: '评价（选填）'),
                ),
                FilledButton(
                  onPressed: _busy ? null : () => _act('提交评价'),
                  child: const Text('提交评价'),
                ),
              ],
            ],
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            OutlinedButton(
              onPressed: () =>
                  context.go(widget.pilot ? '/pilot/jobs' : '/dispatch/orders'),
              child: const Text('返回订单列表'),
            ),
          ],
        ),
      ),
    );
  }
}
