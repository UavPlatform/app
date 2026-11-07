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
    this.compactChat = false,
    this.compactNavigation = false,
    this.navigationSide,
  });
  final DispatchOrder order;
  final bool pilot;
  final bool hideChat, chatOnly, compactChat;
  final String? navigationSide;
  final bool compactNavigation;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.waiting || order.awaitingDeposit || order.cancelled) {
      return const SizedBox.shrink();
    }
    void openChat() => context.push(
      Uri(
        path: '${pilot ? '/pilot' : ''}/dispatch/orders/${order.id}/chat',
        queryParameters: {'version': '${order.data.assignmentVersion}'},
      ).toString(),
    );
    Future<void> navigate(String side) async {
      final ok = await ref
          .read(dispatchNavigationProvider)
          .open(order.data.fields ?? {}, side);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开高德导航，请核对坐标或手动在地图中查找运单地点')),
        );
      }
    }

    if (compactChat) {
      return DispatchOrderOutlineAction(
        onPressed: openChat,
        label: order.completed ? '查看订单聊天' : '订单聊天',
      );
    }
    final side = navigationSide;
    if (side != null) {
      if (!pilot || order.completed || chatOnly) return const SizedBox.shrink();
      return Tooltip(
        message: side == 'start' ? '导航到起点' : '导航到终点',
        child: TextButton.icon(
          onPressed: () => navigate(side),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(0, 38),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFF1D6FE9),
            backgroundColor: const Color(0xFFE8F3FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.navigation_rounded, size: 15),
          label: const Text('导航'),
        ),
      );
    }
    if (compactNavigation && pilot && !order.completed && !chatOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          const Text(
            '地面出行导航（不用于无人机航线规划）',
            style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          Row(
            spacing: 10,
            children: [
              for (final side in ['start', 'end'])
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => navigate(side),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      backgroundColor: const Color(0xFFE8F3FF),
                      foregroundColor: const Color(0xFF1D6FE9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: Text(
                      side == 'start' ? '导航到起点' : '导航到终点',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (!hideChat)
          OutlinedButton.icon(
            onPressed: openChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(order.completed ? '查看订单聊天' : '订单聊天'),
          ),
        if (pilot && !order.completed && !chatOnly) ...[
          const FlowNotice('地面出行导航，不用于无人机航线规划。'),
          for (final side in ['start', 'end'])
            OutlinedButton.icon(
              onPressed: () => navigate(side),
              icon: const Icon(Icons.directions_outlined),
              label: Text(side == 'start' ? '导航到起点' : '导航到终点'),
            ),
        ],
      ],
    );
  }
}

class DispatchOrderOutlineAction extends StatelessWidget {
  const DispatchOrderOutlineAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D6FE9),
        disabledForegroundColor: const Color(0xFF9CA3AF),
        side: BorderSide(
          color: onPressed == null
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF1D6FE9),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}
