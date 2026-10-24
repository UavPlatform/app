import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/generated/openapi_models.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../widgets/flow_ui.dart';

class DispatchPriceCard extends ConsumerWidget {
  const DispatchPriceCard({
    super.key,
    required this.quote,
    this.bill,
    this.expanded = false,
  });
  final ApiDispatchQuoteVO? quote;
  final ApiDispatchBillVO? bill;
  final bool expanded;
  String money(num? value) =>
      value == null ? '待确认' : '¥${value.toStringAsFixed(2)}';
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = quote;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: scheme.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '按距离计价',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '模拟支付',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (q == null)
              const Text('此订单没有计价快照，请联系平台处理。')
            else ...[
              Text(
                '运单总价：${money(q.totalAmount)}',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              Text('定金：${money(q.depositAmount)}，结算时抵扣'),
              if (expanded) ...[
                Text('起终点直线距离：${q.distanceMeters?.toStringAsFixed(2)} m'),
                Text(
                  '距离费：${money(q.distanceCharge)}（${money(q.pricePerMeter)}/m）',
                ),
                Text('飞手服务费：${money(q.pilotServiceFee)} / 单'),
                const Text('按下单时确认的价格结算；天气、设备租赁和飞行时长暂不计费。'),
              ],
            ],
            if (bill?.finalAmount != null) ...[
              Text('结算总价：${money(bill!.finalAmount)}'),
              Text(
                (bill!.balanceAmount ?? 0) < 0
                    ? '应退差额：${money(-bill!.balanceAmount!)}（模拟退款）'
                    : '抵扣定金后尾款：${money(bill!.balanceAmount)}',
              ),
              if (expanded && bill!.settlementReference != null)
                FlowValue('模拟结算流水', bill!.settlementReference!),
            ],
            if (!expanded && q != null)
              OutlinedButton.icon(
                onPressed: () {
                  final scope = ref.read(waybillDraftScopeProvider);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FlowDetailPage(
                        title: '费用明细',
                        scope: scope,
                        builder: (_) => FlowList(
                          children: [
                            DispatchPriceCard(
                              quote: q,
                              bill: bill,
                              expanded: true,
                            ),
                            const FlowNotice('当前为模拟收退款，不会真实扣款。', warning: true),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('查看费用明细'),
              ),
          ],
        ),
      ),
    );
  }
}
