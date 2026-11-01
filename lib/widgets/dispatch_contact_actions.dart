import 'flow_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/dispatch_order.dart';
import '../services/dispatch_navigation.dart';

class DispatchContactActions extends ConsumerWidget {
  const DispatchContactActions({
    super.key,
    required this.order,
    this.pilot = false,
    this.hideChat = false,
    this.chatOnly = false,
  });
  final DispatchOrder order;
  final bool pilot;
  final bool hideChat, chatOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.waiting || order.awaitingDeposit || order.cancelled) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (!hideChat)
          OutlinedButton.icon(
            onPressed: () => context.push(
              Uri(
                path:
                    '${pilot ? '/pilot' : ''}/dispatch/orders/${order.id}/chat',
                queryParameters: {'version': '${order.data.assignmentVersion}'},
              ).toString(),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(order.completed ? '查看订单聊天' : '订单聊天'),
          ),
        if (pilot && !order.completed && !chatOnly) ...[
          const FlowNotice('地面出行导航，不用于无人机航线规划。'),
          for (final side in ['start', 'end'])
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await ref
                    .read(dispatchNavigationProvider)
                    .open(order.data.fields ?? {}, side);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('无法打开高德导航，请核对坐标或手动在地图中查找运单地点'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.directions_outlined),
              label: Text(side == 'start' ? '导航到起点' : '导航到终点'),
            ),
        ],
      ],
    );
  }
}
