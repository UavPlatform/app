import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/chat_provider.dart';

class MessageListPage extends ConsumerWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionListProvider);

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
                      child: Text('暂无会话',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
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
                            child: Text(title[0].toUpperCase(),
                                style: const TextStyle(color: AppColors.primary)),
                          ),
                          title: Text(title,
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            s.lastMessage ?? s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.onSurfaceVariant),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.outline),
                          onTap: () => context.push(
                              '/chat/${s.id}?name=${Uri.encodeComponent(title)}'),
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
            child: const Icon(Icons.campaign_outlined,
                color: AppColors.warning, size: 22),
          ),
          title: const Text('系统通知',
              style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('查看系统消息和订单动态',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
          onTap: () {},
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}
