import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class MessageListPage extends ConsumerStatefulWidget {
  const MessageListPage({super.key});

  @override
  ConsumerState<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends ConsumerState<MessageListPage> {
  bool _connectedRealtime = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionListProvider);
    final uid = int.tryParse(ref.watch(authProvider).user?.userId ?? '') ?? 0;
    if (!_connectedRealtime && uid > 0) {
      _connectedRealtime = true;
      Future.microtask(
        () => ref.read(chatWebSocketServiceProvider).ensureConnected(uid),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('消息')),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => ref.read(sessionListProvider.notifier).load(),
        child: const Icon(Icons.refresh),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSystemNotice(context),
                if (state.sessions.isEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(
                      child: Text(
                        '暂无会话',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...state.sessions.map((s) {
                    final title = s.otherUserName ?? s.name;
                    return Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              title[0].toUpperCase(),
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            s.lastMessage ?? s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatSessionTime(s.sortTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (s.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    s.unreadCount > 99
                                        ? '99+'
                                        : s.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.outline,
                                  size: 18,
                                ),
                            ],
                          ),
                          onTap: () => context.push(
                            '/chat/${s.id}?otherUserName=${Uri.encodeComponent(title)}',
                          ),
                        ),
                        const Divider(height: 1, indent: 72),
                      ],
                    );
                  }),
              ],
            ),
    );
  }

  Widget _buildSystemNotice(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.statusPending.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          title: const Text(
            '系统通知',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: const Text(
            '查看系统消息和订单动态',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
          onTap: () {},
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }

  String _formatSessionTime(int timestamp) {
    if (timestamp <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final minute = dt.minute.toString().padLeft(2, '0');
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour}:$minute';
    }
    return '${dt.month}-${dt.day}';
  }
}
