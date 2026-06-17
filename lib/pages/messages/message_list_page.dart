import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/message_model.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = MockDataService.messages;
    final systemMessages = messages.where((m) => m.type == MessageType.system).toList();
    final chatMessages = messages.where((m) => m.type == MessageType.chat).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息中心'),
      ),
      body: ListView(
        children: [
          // 系统通知入口
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildQuickEntry(
              icon: Icons.notifications_outlined,
              label: '系统通知',
              count: systemMessages.where((m) => !m.isRead).length,
            ),
          ),
          const Divider(),

          // 消息列表
          ...messages.map((message) => _buildMessageTile(context, message)),
        ],
      ),
    );
  }

  Widget _buildQuickEntry({required IconData icon, required String label, required int count}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Badge(
              isLabelVisible: count > 0,
              label: Text('$count', style: const TextStyle(fontSize: 10)),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, Message message) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: message.type == MessageType.system
                ? AppColors.primaryLight
                : AppColors.surfaceVariant,
            child: Icon(
              message.type == MessageType.system
                  ? Icons.notifications
                  : Icons.person,
              color: message.type == MessageType.system
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatTime(message.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: message.isRead
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: !message.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {},
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}-${time.day}';
    }
  }
}
