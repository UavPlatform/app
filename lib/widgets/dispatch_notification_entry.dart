import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dispatch_notification_provider.dart';

// REQ-ALL-XC-005: both entry points consume one recipient-scoped unread source.
class DispatchNotificationEntry extends ConsumerWidget {
  const DispatchNotificationEntry({super.key, this.menu = false});
  final bool menu;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(dispatchUnreadProvider);
    final count = unread.asData?.value;
    final icon = Badge(
      isLabelVisible: count != null && count > 0,
      label: Text(count != null && count > 99 ? '99+' : '$count'),
      child: const Icon(Icons.notifications_outlined),
    );
    if (menu) {
      return ListTile(
        leading: icon,
        title: const Text('消息通知'),
        subtitle: unread.hasError ? const Text('未读数暂不可用，点击查看通知') : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/notifications'),
      );
    }
    return IconButton(
      tooltip: count == null ? '消息通知' : '消息通知，$count 条未读',
      icon: icon,
      onPressed: () => context.push('/notifications'),
    );
  }
}
