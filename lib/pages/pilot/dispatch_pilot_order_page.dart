import '../../providers/map_provider.dart';
import '../../widgets/flow_ui.dart';
import '../waybill/dispatch_order_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/dispatch_order.dart';
import '../waybill/dispatch_fulfillment_pages.dart';
import '../waybill/dispatch_price_card.dart';
import '../waybill/dispatch_material_panel.dart';
import '../../providers/dispatch_order_provider.dart';
import '../../providers/waybill_draft_provider.dart';
import '../../services/phone_dialer.dart';
import '../../widgets/dispatch_contact_actions.dart';
import '../waybill/dispatch_order_app_bar.dart';

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
    String siteCondition(String side) => fields['$side.landing'] == 'yes'
        ? '可降落'
        : fields['$side.winchMin'] != null && fields['$side.winchMax'] != null
        ? '绞盘 ${fields['$side.winchMin']}–${fields['$side.winchMax']} m'
        : '待核对';
    final cargo = _workCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 17, color: _ink),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '货物与吊点核对',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _cargoLine(
            '货物规格',
            '${fields['category']} · ${dispatchWeightLabel(fields)} · ${fields['count']} 件',
          ),
          _cargoLine(
            '外箱尺寸',
            '${fields['length']} × ${fields['width']} × ${fields['height']} cm',
          ),
          _cargoLine(
            '包装与吊点',
            '包装 ${fields['packaging']}  |  吊点：${fields['lifting']}',
          ),
          if (order.arrived)
            _cargoLine(
              '场地条件',
              '起点${siteCondition('start')} · 终点${siteCondition('end')}',
            ),
        ],
      ),
    );
    Widget site(String side) => _workCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          _siteRow(context, ref, fields, side),
          const Text(
            '地面导航，仅供前往现场参考',
            style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
    Widget page(Widget? bottom, Widget? release) => Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: DispatchOrderAppBar(
        title: title,
        onRefresh: () => ref.invalidate(dispatchPilotOrderProvider(order.id)),
        onReturn: () => context.go('/pilot/jobs'),
      ),
      bottomNavigationBar: bottom,
      body: FlowList(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        spacing: 12,
        children: [
          if (order.arrived) cargo else site('start'),
          if (order.arrived)
            DispatchMaterialPanel(orderId: order.id, stage: order.data.stage),
          DispatchOrderStatusStrip(order: order, step: step),
          Text(
            order.cancelled
                ? '需求方已取消，请停止执行'
                : order.arrived
                ? '开始运输后可上传送达凭证'
                : '到达起点后确认到场',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (order.arrived) site('start'),
          site('end'),
          if (!order.arrived) cargo,
          _workCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                DispatchPriceCard(
                  quote: order.data.bill?.quote,
                  orderId: order.id,
                  order: order,
                  pilot: true,
                  compact: true,
                ),
                const Divider(height: 1, color: Color(0xFFF0F2F5)),
                DispatchOrderInformationLink(
                  order: order,
                  pilot: true,
                  compact: true,
                ),
              ],
            ),
          ),
          const Text(
            '环境评估为演示样例，请以现场核对为准',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
          if (release != null)
            Align(alignment: Alignment.centerRight, child: release),
        ],
      ),
    );
    return order.cancelled
        ? page(null, null)
        : _PilotOrderActions(order: order, builder: page);
  }

  Widget _siteRow(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> fields,
    String side,
  ) {
    final start = side == 'start';
    final label = orderEndpointLabel(ref, fields, side);
    final place = label?.name ?? '';
    final address = label?.address ?? '';
    final site = fields['$side.site']?.toString().trim() ?? '';
    final location = place.isNotEmpty ? place : site;
    final landing = fields['$side.landing'] == 'yes';
    return Row(
      spacing: 8,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: start ? _blue : const Color(0xFFFF6B00),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            start ? '起' : '终',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    location.isEmpty ? (start ? '起点' : '终点') : location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: landing
                          ? const Color(0xFFE6F8F0)
                          : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      landing
                          ? '可降落'
                          : '绞盘高度 ${fields['$side.winchMin']}–${fields['$side.winchMax']} m',
                      style: TextStyle(
                        fontSize: 11,
                        color: landing
                            ? const Color(0xFF00B578)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
              if (address.isNotEmpty && address != location)
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              Text(
                '${fields['$side.contact'] ?? ''} · ${fields['$side.phone'] ?? ''}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
              if ((fields['$side.notes'] ?? '').toString().isNotEmpty)
                Text(
                  '备注：${fields['$side.notes']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
            ],
          ),
        ),
        if (!order.cancelled) ...[
          IconButton(
            tooltip: '拨打联系人',
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
            style: IconButton.styleFrom(
              fixedSize: const Size(38, 38),
              minimumSize: const Size(38, 38),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: const Color(0xFFF2F4F7),
            ),
            icon: const Icon(
              Icons.phone_in_talk_rounded,
              size: 18,
              color: _ink,
            ),
          ),
          DispatchContactActions(
            order: order,
            pilot: true,
            navigationSide: side,
          ),
        ],
      ],
    );
  }

  Widget _cargoLine(String label, String value) => Row(
    spacing: 10,
    children: [
      SizedBox(
        width: 74,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: _ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

const _blue = Color(0xFF1D6FE9);
const _ink = Color(0xFF1F2329);

Widget _workCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(16),
}) => Material(
  color: Colors.white,
  clipBehavior: Clip.antiAlias,
  borderRadius: BorderRadius.circular(14),
  child: Padding(padding: padding, child: child),
);

class _PilotOrderActions extends ConsumerStatefulWidget {
  const _PilotOrderActions({required this.order, required this.builder});
  final DispatchOrder order;
  final Widget Function(Widget bottom, Widget release) builder;
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
  Widget build(BuildContext context) {
    final primaryStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 46),
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE5E7EB),
      disabledForegroundColor: const Color(0xFF9CA3AF),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
    final bottom = DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: DispatchContactActions(
                      order: widget.order,
                      pilot: true,
                      chatOnly: true,
                      compactChat: true,
                    ),
                  ),
                  if (widget.order.preparing)
                    Expanded(
                      child: FilledButton(
                        style: primaryStyle,
                        onPressed: _busy ? null : () => _act(false),
                        child: const Text('我已到场'),
                      ),
                    ),
                  if (widget.order.arrived)
                    Expanded(
                      child: FilledButton(
                        style: primaryStyle,
                        onPressed: _busy
                            ? null
                            : () => _act(false, start: true),
                        child: const Text('开始运输'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return widget.builder(
      bottom,
      TextButton(
        onPressed: _busy ? null : () => _act(true),
        child: const Text('取消接单，重新派单'),
      ),
    );
  }
}
