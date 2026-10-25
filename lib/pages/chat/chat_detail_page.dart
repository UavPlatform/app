import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/system_message_card.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final int sessionId;
  final String? sessionName;
  final bool readOnly;
  const ChatDetailPage({
    super.key,
    required this.sessionId,
    this.sessionName,
    this.readOnly = false,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _syncTimer;
  Timer? _readTimer;
  bool _connectedRealtime = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSyncTimer();
    // t50：进入会话显式推进已读（POST /chat/Message/read），本地未读同步清零
    Future.microtask(() {
      if (!mounted) return;
      unawaited(_refreshMessages(silent: true));
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      unawaited(_refreshMessages(silent: true));
    });
  }

  Future<void> _refreshMessages({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      final uid = int.tryParse(ref.read(authProvider).user?.userId ?? '') ?? 0;
      unawaited(ref.read(chatWebSocketServiceProvider).ensureConnected(uid));
    }
    await ref
        .read(messageListProvider(widget.sessionId).notifier)
        .load(silent: silent);
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (ref.read(messageListProvider(widget.sessionId)).error != null) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    await ref
        .read(sessionListProvider.notifier)
        .markSessionRead(widget.sessionId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSyncTimer();
      unawaited(_refreshMessages());
    } else {
      _syncTimer?.cancel();
      _readTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _readTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (widget.readOnly) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final sent = await ref
        .read(messageListProvider(widget.sessionId).notifier)
        .sendMessage(content: text);
    if (!sent && mounted) {
      _textController.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('发送失败，请稍后重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageListProvider(widget.sessionId));
    final uid = int.tryParse(ref.watch(authProvider).user?.userId ?? '') ?? 0;
    ref.listen(messageListProvider(widget.sessionId), (previous, next) {
      if (next.messages.isEmpty || !mounted) return;
      final latest = next.messages.last;
      if (previous?.messages.lastOrNull?.msgId == latest.msgId) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (WidgetsBinding.instance.lifecycleState != null &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      _readTimer?.cancel();
      _readTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted &&
            ModalRoute.of(context)?.isCurrent == true &&
            (WidgetsBinding.instance.lifecycleState == null ||
                WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed)) {
          ref
              .read(sessionListProvider.notifier)
              .markSessionRead(widget.sessionId);
        }
      });
      // Follow new messages only while near the latest messages, or after sending.
      if (!_scrollController.hasClients ||
          _scrollController.position.maxScrollExtent -
                  _scrollController.offset <
              80 ||
          latest.fromUserId == uid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
    if (!_connectedRealtime && uid > 0) {
      _connectedRealtime = true;
      Future.microtask(() {
        if (mounted) {
          ref.read(chatWebSocketServiceProvider).ensureConnected(uid);
        }
      });
    }
    final title = widget.sessionName ?? '聊天';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: '刷新消息',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _refreshMessages(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.loading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _refreshMessages(),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      reverse: false,
                      itemCount: state.messages.isEmpty
                          ? 1
                          : state.messages.length,
                      itemBuilder: (context, index) {
                        if (state.messages.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: Text('暂无消息，发送一条开始沟通')),
                          );
                        }
                        final msg = state.messages[index];
                        // t33：系统消息（NOTICE/ORDER，fromUserId=0）渲染为系统卡片
                        if (isSystemMessage(msg)) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SystemMessageCard(message: msg),
                          );
                        }
                        final isMine = msg.fromUserId == uid;
                        return Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: isMine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMine)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      bottom: 2,
                                    ),
                                    child: Text(
                                      _otherName(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const Divider(height: 1),
          if (widget.readOnly)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('订单已结单，聊天记录仅供查看'),
            ),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: state.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.primary),
                    onPressed: state.sending ? null : _send,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _otherName() {
    return widget.sessionName ?? '';
  }
}
