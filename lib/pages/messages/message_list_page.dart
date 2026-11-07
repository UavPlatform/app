import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/session_vo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'system_messages_view.dart';

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

    // t33：系统通知专属会话（chat_session.type=2，懒创建）单独聚合展示
    final systemSession = _systemSessionOf(state.sessions);
    final chatSessions = state.sessions.where((s) => s.type != 2).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '消息',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(sessionListProvider.notifier).load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _buildSystemNotice(context, systemSession),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
                    child: Text(
                      '沟通列表',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: chatSessions.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 36,
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    '暂无订单沟通记录',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < chatSessions.length;
                                  i++
                                ) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      indent: 76,
                                      endIndent: 16,
                                      color: Color(0xFFF0F2F5),
                                    ),
                                  _buildConversation(context, chatSessions[i]),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildConversation(BuildContext context, SessionVo s) {
    final title = s.otherUserName ?? s.name;
    return InkWell(
      onTap: () => context.push(
        '/chat/${s.id}?otherUserName=${Uri.encodeComponent(title)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F3FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                title.isEmpty ? '?' : title.characters.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D6FE9),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2329),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatSessionTime(s.sortTime),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.lastMessage ?? s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                      if (s.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        _unreadBadge(s.unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unreadBadge(int unread) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFEF4444),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      unread > 99 ? '99+' : unread.toString(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  SessionVo? _systemSessionOf(List<SessionVo> sessions) {
    for (final s in sessions) {
      if (s.type == 2) return s;
    }
    return null;
  }

  /// t33：系统通知入口接通——聚合展示系统会话中的状态通知卡片，
  /// 未读红点与系统会话未读数联动（深度修复属 2-1）。
  Widget _buildSystemNotice(BuildContext context, SessionVo? systemSession) {
    final unread = systemSession?.unreadCount ?? 0;
    final hasUnread = systemSession != null && unread > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SystemMessagesView(sessionId: systemSession?.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    size: 26,
                    color: Color(0xFFFF6B00),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '系统通知',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2329),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasUnread ? '你有新的系统消息' : '查看系统消息和订单动态',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  _unreadBadge(unread),
                ],
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),
        ),
      ),
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
