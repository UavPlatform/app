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
    this.orderId,
    this.pilot = false,
  });
  final ApiDispatchQuoteVO? quote;
  final ApiDispatchBillVO? bill;
  final bool expanded, pilot;
  final String? orderId;
  String money(num? value) =>
      value == null ? '待确认' : '¥${value.toStringAsFixed(2)}';
  void _showFeeDetailBottomSheet(BuildContext context, WidgetRef ref) =>
      showDispatchDetailSheet(
        context,
        title: '费用明细',
        scope: ref.read(waybillDraftScopeProvider),
        builder: (_) => Consumer(
          builder: (context, ref, _) {
            if (orderId == null) return _details(quote, bill);
            final live = pilot
                ? ref.watch(dispatchPilotOrderProvider(orderId!))
                : ref.watch(dispatchOrderProvider(orderId!));
            return live.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(16),
                child: Text('费用暂不可用，请返回重试'),
              ),
              data: (order) => _details(
                order.data.bill?.quote,
                order.data.bill,
                order: order,
              ),
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
              (b?.balanceAmount ?? 0) < 0 ? '应退差额（模拟退款）' : '抵扣定金后尾款',
              money(
                (b?.balanceAmount ?? 0) < 0
                    ? -b!.balanceAmount!
                    : b?.balanceAmount,
              ),
            ),
            if (b?.settlementReference != null)
              ('模拟结算流水', b!.settlementReference!),
          ],
        ),
        const Text(
          '按下单时确认的价格结算；天气、设备租赁和飞行时长暂不计费。',
          style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 8),
        const Text(
          '当前为模拟收退款，不会真实扣款。',
          style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = quote;
    if (expanded) return _details(q, bill);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calculate_outlined,
                      size: 18,
                      color: Color(0xFF1D6FE9),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '按距离计价',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '模拟支付',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (q == null)
                  const Text('此订单没有计价快照，请联系平台处理。')
                else ...[
                  const Text(
                    '运单总价',
                    style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(q.totalAmount),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D6FE9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '定金：${money(q.depositAmount)}，结算时抵扣',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
                if (bill?.finalAmount != null) ...[
                  const SizedBox(height: 8),
                  Text('结算总价：${money(bill!.finalAmount)}'),
                  Text(
                    (bill!.balanceAmount ?? 0) < 0
                        ? '应退差额：${money(-bill!.balanceAmount!)}（模拟退款）'
                        : '抵扣定金后尾款：${money(bill!.balanceAmount)}',
                  ),
                ],
              ],
            ),
          ),
          if (q != null) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            InkWell(
              onTap: () => _showFeeDetailBottomSheet(context, ref),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '查看费用明细',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1D6FE9)),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF1D6FE9),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
