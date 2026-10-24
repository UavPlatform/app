import '../../theme/dispatch_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../widgets/flow_ui.dart';
import 'dispatch_price_card.dart';

class DispatchOrderInformationLink extends StatelessWidget {
  const DispatchOrderInformationLink({
    super.key,
    required this.order,
    this.pilot = false,
  });
  final DispatchOrder order;
  final bool pilot;
  @override
  Widget build(BuildContext context) => FlowDetailsLink(
    title: '运单资料与账单',
    summary: '${shortReference(order.id)} · 联系人、场地、完整编号与支付记录',
    builder: (_) =>
        DispatchOrderInformationPage(orderId: order.id, pilot: pilot),
  );
}

class DispatchOrderInformationPage extends ConsumerWidget {
  const DispatchOrderInformationPage({
    super.key,
    required this.orderId,
    this.pilot = false,
  });
  final String orderId;
  final bool pilot;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live permission-checked order, never pass a stale order snapshot.
    ref.watch(waybillDraftScopeProvider);
    final state = pilot
        ? ref.watch(dispatchPilotOrderProvider(orderId))
        : ref.watch(dispatchOrderProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('运单资料与账单')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () {
              if (pilot) {
                ref.invalidate(dispatchPilotOrderProvider(orderId));
              } else {
                ref.invalidate(dispatchOrderProvider(orderId));
              }
            },
            child: const Text('资料暂不可用，重新查询'),
          ),
        ),
        data: (order) {
          final fields = order.data.fields ?? {};
          String value(String key) => (fields[key] ?? '').toString();
          return FlowList(
            children: [
              FlowHeader(
                title: order.stageLabel,
                subtitle: '完整运单资料与费用记录',
                icon: Icons.receipt_long_outlined,
              ),
              FlowValue('完整运单号', order.id),
              FlowValue(
                '货物',
                '${value('category')} · ${dispatchWeightLabel(fields)} · ${value('count')} 件',
              ),
              FlowValue('包装与吊点', '${value('packaging')}\n${value('lifting')}'),
              FlowValue(
                '尺寸（厘米）',
                '${value('length')} × ${value('width')} × ${value('height')}',
              ),
              for (final side in ['start', 'end'])
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [
                        Text(
                          side == 'start' ? '起点资料' : '终点资料',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        FlowValue('场地', value('$side.site')),
                        FlowValue(
                          '坐标',
                          '${value('$side.lat')}, ${value('$side.lng')}',
                        ),
                        FlowValue(
                          '联系人',
                          '${value('$side.contact')} · ${value('$side.phone')}',
                        ),
                        FlowValue(
                          '交付方式',
                          value('$side.landing') == 'yes'
                              ? '落地放货'
                              : '绞盘吊放 ${value('$side.winchMin')}–${value('$side.winchMax')} m',
                        ),
                        if (value('$side.notes').isNotEmpty)
                          FlowValue('备注', value('$side.notes')),
                      ],
                    ),
                  ),
                ),
              FlowValue(
                '出发时间',
                value('timeMode') == 'scheduled'
                    ? value('scheduledAt').replaceAll('T', ' ')
                    : '立即出发',
              ),
              DispatchPriceCard(
                quote: order.data.bill?.quote,
                bill: order.data.bill,
                expanded: true,
              ),
              FlowValue(
                '定金',
                '¥${order.data.depositAmount!.toStringAsFixed(2)}',
              ),
              if (order.data.paymentReference != null)
                FlowValue('模拟支付流水', order.data.paymentReference!),
              if (order.data.refundReference != null)
                FlowValue('模拟退款流水', order.data.refundReference!),
              FlowValue('更新于', order.data.updatedAt ?? '未知'),
              const FlowNotice('支付与退款为模拟通道，无真实资金变动。', warning: true),
            ],
          );
        },
      ),
    );
  }
}

class DispatchOrderCard extends StatelessWidget {
  const DispatchOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });
  final DispatchOrder order;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final fields = order.data.fields ?? {};
    final scheme = Theme.of(context).colorScheme;
    final accent = DispatchPalette.status(context, order.data.stage);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${fields['category'] ?? '吊运'} · ${shortReference(order.id)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.stageLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${fields['start.site'] ?? '起点'} → ${fields['end.site'] ?? '终点'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.data.createdAt ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '查看进度',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
