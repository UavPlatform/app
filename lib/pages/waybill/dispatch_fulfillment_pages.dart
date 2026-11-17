import 'dispatch_detail_surface.dart';
import 'dispatch_order_app_bar.dart';
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
  final _scroll = ScrollController();
  final _materialAnchor = GlobalKey();

  void _showMaterials() {
    final target = _materialAnchor.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
      );
    } else if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant DispatchFulfillmentShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.pilot != widget.pilot ||
        oldWidget.order.data.stage != widget.order.data.stage) {
      _materials = [];
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _act(String action) async {
    if (_busy) return;
    final scope = ref.read(waybillDraftScopeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == '模拟支付尾款' ? '支付尾款' : action),
        content: Text(
          action == '模拟支付尾款'
              ? '确认支付本单尾款？'
              : action == '取消运单'
              ? '定金将全额退回。取消业务订单不会自动停止实际飞行，请与飞手联系处置。'
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
      if (!mounted ||
          scope != ref.read(waybillDraftScopeProvider) ||
          loans.isEmpty) {
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
        if (keep == true ||
            !mounted ||
            scope != ref.read(waybillDraftScopeProvider)) {
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
    final balanceDue =
        !widget.pilot &&
        order.completed &&
        order.data.fundsStatus == 'BALANCE_DUE';
    final balance = bill?.balanceAmount;
    final paymentLabel = balance == null
        ? '支付尾款'
        : '支付尾款 ¥${balance.toStringAsFixed(2)}';
    final missingProof = purpose != null && _materials.isEmpty;
    final confirmation = widget.pilot ? '确认送达' : '确认收货并结单';
    final actionLabel = balanceDue
        ? paymentLabel
        : missingProof
        ? (widget.pilot ? '上传送达凭证' : '上传收货凭证')
        : '$confirmation（已核验 ${_materials.length} 项）';
    final materials = KeyedSubtree(
      key: _materialAnchor,
      child: DispatchMaterialPanel(
        key: ValueKey('${order.id}:$purpose'),
        orderId: order.id,
        purpose: purpose,
        stage: order.data.stage,
        initialSelected: _materials,
        onSelected: purpose == null
            ? null
            : (ids) => setState(() => _materials = ids),
      ),
    );
    return Theme(
      data: dispatchDetailTheme(Theme.of(context)),
      child: Scaffold(
        appBar: DispatchOrderAppBar(
          title: order.stageLabel,
          onRefresh: () {
            ref.invalidate(dispatchOrderProvider(order.id));
            ref.invalidate(dispatchPilotOrderProvider(order.id));
          },
          onReturn: () =>
              context.go(widget.pilot ? '/pilot/jobs' : '/dispatch/orders'),
        ),
        bottomNavigationBar:
            purpose == null && !balanceDue && !_busy && _error == null
            ? null
            : Material(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        if (_busy) const LinearProgressIndicator(),
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (missingProof)
                          Text(
                            widget.pilot ? '需上传并核验凭证后确认送达' : '需上传并核验凭证后结单',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (purpose != null || balanceDue)
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : missingProof
                                ? _showMaterials
                                : () => _act(
                                    balanceDue ? '模拟支付尾款' : confirmation,
                                  ),
                            child: Text(
                              actionLabel,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
        body: FlowList(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          spacing: 6,
          children: [
            if (balanceDue)
              DispatchPriceCard(
                quote: bill?.quote,
                bill: bill,
                orderId: order.id,
                order: order,
              ),
            DispatchOrderStatusStrip(
              order: order,
              step: order.transporting
                  ? 4
                  : order.confirming
                  ? 5
                  : 6,
            ),
            if (purpose != null) materials,
            if (order.transporting) ...[
              DispatchFlightPanel(
                key: ValueKey(order.id),
                orderId: order.id,
                destination: destination,
              ),
              if (!widget.pilot) const Text('送达后将通知你确认收货。'),
            ],
            if (order.confirming)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: DispatchOrderGuide(
                    widget.pilot
                        ? '送达凭证已提交，等待需求方上传收货凭证并确认。'
                        : '请查看飞手送达凭证，上传本次收货凭证后确认收货。',
                  ),
                ),
              ),
            if (order.completed) ...[
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                      child: DispatchOrderGuide(
                        order.data.fundsStatus == 'BALANCE_DUE'
                            ? '已确认收货，待支付尾款'
                            : '已结算',
                      ),
                    ),
                    DispatchOrderInformationLink(
                      order: order,
                      pilot: widget.pilot,
                      compact: true,
                    ),
                  ],
                ),
              ),
              if (!balanceDue)
                DispatchPriceCard(
                  quote: bill?.quote,
                  bill: bill,
                  orderId: order.id,
                  order: order,
                  pilot: widget.pilot,
                ),
            ] else
              Card(
                margin: EdgeInsets.zero,
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    DispatchPriceCard(
                      quote: bill?.quote,
                      bill: bill,
                      orderId: order.id,
                      order: order,
                      pilot: widget.pilot,
                      compact: true,
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F2F5)),
                    DispatchOrderInformationLink(
                      order: order,
                      pilot: widget.pilot,
                      compact: true,
                    ),
                  ],
                ),
              ),
            if (widget.pilot && !order.completed)
              DispatchContactActions(
                order: order,
                pilot: widget.pilot,
                hideChat: true,
                compactNavigation: true,
              ),
            if (purpose == null) materials,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: DispatchContactActions(
                order: order,
                pilot: widget.pilot,
                chatOnly: true,
                compactChat: true,
              ),
            ),
            if (!widget.pilot && !order.completed)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : () => _act('取消运单'),
                  child: const Text('取消运单'),
                ),
              ),
            if (order.completed) ...[
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
          ],
        ),
      ),
    );
  }
}
