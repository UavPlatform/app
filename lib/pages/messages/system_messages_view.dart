// 系统通知聚合页（t33，APP P3-4 空壳消除）：
// 聚合展示系统会话（chat_session.type=2）中的任务状态通知卡片。
// 未读数深度修复（进入会话推进 lastReadTime）属批次 2-1，此处仅展示层。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/chat_api.dart';
import '../../models/message_vo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/system_message_card.dart';

class SystemMessagesView extends ConsumerStatefulWidget {
  /// 已知的系统会话 id（消息页入口传入）；为空则自行从会话列表查找。
  final int? sessionId;

  const SystemMessagesView({super.key, this.sessionId});

  @override
  ConsumerState<SystemMessagesView> createState() => _SystemMessagesViewState();
}

class _SystemMessagesViewState extends ConsumerState<SystemMessagesView> {
  List<MessageVo> _messages = [];
  bool _loading = true;
  String? _error;
  int? _resolvedSessionId;

  ChatApi get _chatApi => ChatApi(ref.read(httpClientProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var sessionId = widget.sessionId;
      if (sessionId == null) {
        final sessions = await _chatApi.listSessions();
        if (!mounted) return;
        if (!sessions.success || sessions.data == null) {
          setState(() {
            _error = sessions.message ?? '加载失败';
            _loading = false;
          });
          return;
        }
        final system = sessions.data!
            .where((s) => s.type == 2)
            .toList()
          ..sort((a, b) => b.sortTime.compareTo(a.sortTime));
        if (system.isEmpty) {
          // 系统通知会话懒创建：尚无通知时会话不存在
          setState(() {
            _messages = [];
            _loading = false;
          });
          return;
        }
        final targetSessionId = system.first.id;
        await _loadMessages(targetSessionId);
      } else {
        await _loadMessages(sessionId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请检查网络';
        _loading = false;
      });
    }
  }

  Future<void> _loadMessages(int sessionId) async {
    final result = await _chatApi.getMessages(sessionId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() {
        _messages = result.data!.where(isSystemMessage).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _loading = false;
      });
    } else {
      setState(() {
        _error = result.message ?? '加载失败';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 已定位系统会话后，本地红点清零（展示层联动，t50）
    final systemSessionId = _resolvedSessionId;
    if (systemSessionId != null) {
      Future.microtask(() {
        if (mounted) {
          ref
              .read(sessionListProvider.notifier)
              .markSessionRead(systemSessionId);
        }
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('系统通知')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _messages.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, index) => SystemMessageCard(
                          message: _messages[index],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 72,
            color: AppColors.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无系统消息',
            style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          const Text(
            '任务状态变更通知（支付/接单/完成等）将在这里展示',
            style: TextStyle(fontSize: 13, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
