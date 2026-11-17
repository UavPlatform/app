import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/generated/openapi_models.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import 'dispatch_detail_surface.dart';

class DispatchPriceCard extends ConsumerWidget {
  const DispatchPriceCard({
    super.key,
    required this.quote,
    this.bill,
    this.expanded = false,
    this.compact = false,
    this.orderId,
    this.pilot = false,
    this.order,
  });
  final ApiDispatchQuoteVO? quote;
  final ApiDispatchBillVO? bill;
  final bool expanded, pilot, compact;
  final String? orderId;
  final DispatchOrder? order;
  String money(num? value) =>
      value == null ? '待确认' : '¥${value.toStringAsFixed(2)}';
  void _showFeeDetailBottomSheet(
    BuildContext context,
    WidgetRef ref,
  ) => showDispatchDetailSheet(
    context,
    title: '费用明细',
    scope: ref.read(waybillDraftScopeProvider),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        if (orderId == null) return _details(quote, bill, order: order);
        final live = pilot
            ? ref.watch(dispatchPilotOrderProvider(orderId!))
            : ref.watch(dispatchOrderProvider(orderId!));
        return live.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(heightFactor: 1, child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('费用暂不可用，请返回重试'),
          ),
          data: (order) =>
              _details(order.data.bill?.quote, order.data.bill, order: order),
        );
      },
    ),
  );

  Widget _details(
    ApiDispatchQuoteVO? q,
    ApiDispatchBillVO? b, {
    DispatchOrder? order,
  }) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DispatchDetailGroup(
          title: '账单明细',
          valueColors: const {'已付定金': Color(0xFF1D6FE9)},
          values: [
            ('计费方式', '按距离计价'),
            ('运单总价', money(q?.totalAmount)),
            (
              order?.data.paymentReference == null ? '定金（结算时抵扣）' : '已付定金',
              '${order?.data.paymentReference != null && q?.depositAmount != null ? '-' : ''}${money(q?.depositAmount)}',
            ),
            (
              '起终点直线距离',
              q?.distanceMeters == null
                  ? '待确认'
                  : '${q!.distanceMeters!.toStringAsFixed(2)} m',
            ),
            (
              '距离费',
              '${money(q?.distanceCharge)}（${money(q?.pricePerMeter)}/m）',
            ),
            ('飞手服务费', '${money(q?.pilotServiceFee)} / 单'),
            if (b?.finalAmount != null) ('结算总价', money(b!.finalAmount)),
            (
              (b?.balanceAmount ?? 0) < 0 ? '应退差额' : '抵扣定金后尾款',
              money(
                (b?.balanceAmount ?? 0) < 0
                    ? -b!.balanceAmount!
                    : b?.balanceAmount,
              ),
            ),
            if (order?.data.paymentReference != null)
              ('支付流水', order!.data.paymentReference!),
            if (order?.data.refundReference != null)
              ('退款流水', order!.data.refundReference!),
            if (b?.settlementReference != null)
              ('结算流水', b!.settlementReference!),
          ],
        ),
        const Text(
          '按下单时确认的价格结算；天气、设备租赁和飞行时长暂不计费。',
          style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = quote;
    if (expanded) return _details(q, bill, order: order);
    final funds = order?.data.fundsStatus;
    final paid = switch (funds) {
      'UNPAID' => 0,
      'PAID' ||
      'BALANCE_DUE' ||
      'SETTLED' ||
      'REFUNDED' => order?.data.depositAmount ?? q?.depositAmount,
      _ => null,
    };
    final balance = bill?.balanceAmount;
    final remaining = switch (funds) {
      'SETTLED' || 'REFUNDED' => 0,
      'BALANCE_DUE' => balance,
      _ => null,
    };
    final summary = InkWell(
      onTap: q == null && orderId == null && bill == null
          ? null
          : () => _showFeeDetailBottomSheet(context, ref),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                _amount(
                  context,
                  '应付总额',
                  bill?.finalAmount ?? q?.totalAmount,
                  primary: true,
                ),
                _amount(context, '已付定金', paid),
                _amount(context, '待付尾款', remaining),
              ],
            ),
            if (q != null || orderId != null || bill != null)
              Text(
                '查看费用明细',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
    return compact
        ? summary
        : Card(clipBehavior: Clip.antiAlias, child: summary);
  }

  Widget _amount(
    BuildContext context,
    String label,
    num? amount, {
    bool primary = false,
  }) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          money(amount),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: primary ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    ),
  );
}
