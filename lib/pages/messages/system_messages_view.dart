import '../../utils/failure_message.dart';
// 系统通知聚合页（t33，APP P3-4 空壳消除）：
// 聚合展示系统会话（chat_session.type=2）中的任务状态通知卡片。
// 成功加载通知后推进服务端已读状态，并同步会话列表红点。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/chat_api.dart';
import '../../models/message_vo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/system_message_card.dart';
import '../../widgets/data_refresh.dart';

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
            _error = resultFailureMessage(sessions, fallback: '加载失败');
            _loading = false;
          });
          return;
        }
        final system = sessions.data!.where((s) => s.type == 2).toList()
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
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = failureMessage(error, fallback: '系统通知暂时无法加载，请稍后刷新');
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
      await ref.read(sessionListProvider.notifier).markSessionRead(sessionId);
    } else {
      setState(() {
        _error = resultFailureMessage(result, fallback: '加载失败');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('系统通知')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? DataRefresh(onRefresh: _load, child: _buildError())
          : _messages.isEmpty
          ? DataRefresh(onRefresh: _load, child: _buildEmpty())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, index) =>
                    SystemMessageCard(message: _messages[index]),
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
