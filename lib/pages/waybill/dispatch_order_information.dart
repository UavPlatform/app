import '../../providers/map_provider.dart';
import '../../theme/dispatch_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dispatch_order.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../widgets/flow_ui.dart';
import 'dispatch_price_card.dart';
import 'dispatch_detail_surface.dart';

class DispatchOrderInformationLink extends ConsumerWidget {
  const DispatchOrderInformationLink({
    super.key,
    required this.order,
    this.pilot = false,
    this.compact = false,
  });
  final DispatchOrder order;
  final bool pilot, compact;
  void _showWaybillInfoBottomSheet(BuildContext context, WidgetRef ref) =>
      showDispatchDetailSheet(
        context,
        title: '运单资料与账单',
        scope: ref.read(waybillDraftScopeProvider),
        builder: (_) => DispatchOrderInformationPage(
          orderId: order.id,
          pilot: pilot,
          embedded: true,
        ),
      );
  @override
  Widget build(BuildContext context, WidgetRef ref) => compact
      ? InkWell(
          onTap: () => _showWaybillInfoBottomSheet(context, ref),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '运单资料与账单',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2329),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '联系人 · 场地 · 支付记录',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Color(0xFF888888)),
              ],
            ),
          ),
        )
      : Card(
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF1D6FE9),
                size: 20,
              ),
            ),
            title: const Text(
              '运单资料与账单',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2329),
              ),
            ),
            subtitle: const Text(
              '联系人 · 场地 · 支付记录',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFFCCCCCC),
              size: 18,
            ),
            onTap: () => _showWaybillInfoBottomSheet(context, ref),
          ),
        );
}

class DispatchOrderInformationPage extends ConsumerWidget {
  const DispatchOrderInformationPage({
    super.key,
    required this.orderId,
    this.pilot = false,
    this.embedded = false,
  });
  final String orderId;
  final bool pilot;
  final bool embedded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live permission-checked order, never pass a stale order snapshot.
    ref.watch(waybillDraftScopeProvider);
    final state = pilot
        ? ref.watch(dispatchPilotOrderProvider(orderId))
        : ref.watch(dispatchOrderProvider(orderId));
    final content = state.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          heightFactor: embedded ? 1 : null,
          child: const CircularProgressIndicator(),
        ),
      ),
      error: (_, _) => Center(
        heightFactor: embedded ? 1 : null,
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
        String endpoint(String side) {
          final label = orderEndpointLabel(ref, fields, side);
          if (label == null) {
            final site = value('$side.site');
            return site.isEmpty ? '暂无地址描述' : site;
          }
          return {
            label.name,
            label.address,
          }.where((part) => part.isNotEmpty).join(' · ');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DispatchDetailGroup(
                title: '路线与场地信息',
                values: [
                  ('完整运单号', order.id),
                  for (final side in ['start', 'end']) ...[
                    (side == 'start' ? '起点场地' : '终点场地', value('$side.site')),
                    (side == 'start' ? '起点地址' : '终点地址', endpoint(side)),
                    (
                      side == 'start' ? '起点作业条件' : '终点作业条件',
                      value('$side.landing') == 'yes'
                          ? '落地放货'
                          : '绞盘吊放 ${value('$side.winchMin')}–${value('$side.winchMax')} m',
                    ),
                    if (value('$side.notes').isNotEmpty)
                      (side == 'start' ? '起点备注' : '终点备注', value('$side.notes')),
                  ],
                  (
                    '出发时间',
                    value('timeMode') == 'scheduled'
                        ? value('scheduledAt').replaceAll('T', ' ')
                        : '立即出发',
                  ),
                ],
              ),
              DispatchDetailGroup(
                title: '联系人信息',
                values: [
                  if (value('start.contact') == value('end.contact') &&
                      value('start.phone') == value('end.phone')) ...[
                    ('联系人', value('start.contact')),
                    ('联系电话', value('start.phone')),
                  ] else ...[
                    (
                      '起点联系人',
                      '${value('start.contact')} · ${value('start.phone')}',
                    ),
                    (
                      '终点联系人',
                      '${value('end.contact')} · ${value('end.phone')}',
                    ),
                  ],
                ],
              ),
              DispatchDetailGroup(
                title: '货物信息',
                values: [
                  (
                    '货物',
                    '${value('category')} · ${dispatchWeightLabel(fields)} · ${value('count')} 件',
                  ),
                  ('包装与吊点', '${value('packaging')}\n${value('lifting')}'),
                  (
                    '尺寸（厘米）',
                    '${value('length')} × ${value('width')} × ${value('height')}',
                  ),
                  if (value('declaredValue').isNotEmpty)
                    ('申报货值', value('declaredValue')),
                ],
              ),
              DispatchDetailGroup(
                title: '支付记录状态',
                values: [
                  ('资金状态', order.data.fundsStatus ?? '未知'),
                  ('定金', '¥${order.data.depositAmount!.toStringAsFixed(2)}'),
                  if (order.data.paymentReference != null)
                    ('支付流水', order.data.paymentReference!),
                  if (order.data.refundReference != null)
                    ('退款流水', order.data.refundReference!),
                  ('更新于', order.data.updatedAt ?? '未知'),
                ],
              ),
              DispatchPriceCard(
                quote: order.data.bill?.quote,
                bill: order.data.bill,
                expanded: true,
              ),
            ],
          ),
        );
      },
    );
    return embedded
        ? content
        : Scaffold(
            appBar: AppBar(title: const Text('运单资料与账单')),
            body: content,
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
