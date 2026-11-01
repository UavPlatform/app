import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/system_message_card.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final int sessionId;
  final String? sessionName;
  final bool readOnly;
  final String? orderId;
  final String? orderStatus;
  const ChatDetailPage({
    super.key,
    required this.sessionId,
    this.sessionName,
    this.readOnly = false,
    this.orderId,
    this.orderStatus,
  });

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _inputFocus = FocusNode();
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
    _inputFocus.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(messageListProvider(widget.sessionId)).error ??
                '消息发送未完成，请稍后重试',
          ),
        ),
      );
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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: SizedBox(
            height: 0.5,
            child: ColoredBox(
              color: Color(0xFFEEEEEE),
              child: SizedBox.expand(),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '刷新消息',
            icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF333333)),
            onPressed: () => _refreshMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOrderContext(),
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
                : LayoutBuilder(
                    builder: (context, constraints) => RefreshIndicator(
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
                            return SizedBox(
                              height: (constraints.maxHeight - 32).clamp(
                                0.0,
                                double.infinity,
                              ),
                              child: _buildEmptyState(),
                            );
                          }
                          final msg = state.messages[index];
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
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMine && _otherName().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        bottom: 4,
                                      ),
                                      child: Text(
                                        _otherName(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888888),
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
                                          MediaQuery.sizeOf(context).width *
                                          0.72,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? const Color(0xFF1D6FE9)
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                          isMine ? 16 : 4,
                                        ),
                                        topRight: Radius.circular(
                                          isMine ? 4 : 16,
                                        ),
                                        bottomLeft: const Radius.circular(16),
                                        bottomRight: const Radius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      msg.content,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.45,
                                        color: isMine
                                            ? Colors.white
                                            : const Color(0xFF1F2329),
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
          ),
          if (!widget.readOnly) _buildQuickPhrases(),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              top: false,
              child: widget.readOnly
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '订单已结单，聊天记录仅供查看',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _inputFocus,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1F2329),
                            ),
                            decoration: InputDecoration(
                              hintText: '输入消息...',
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF3F4F6),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            tooltip: '发送消息',
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF1D6FE9),
                              disabledBackgroundColor: const Color(0xFF1D6FE9),
                              shape: const CircleBorder(),
                            ),
                            icon: state.sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                            onPressed: state.sending ? null : _send,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderContext() {
    final id = widget.orderId;
    final reference = id == null || id.isEmpty
        ? '当前会话沟通'
        : '运单 ${id.length > 16 ? '${id.substring(0, 6)}…${id.substring(id.length - 4)}' : id}';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3FF),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 16,
              color: Color(0xFF1D6FE9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F8F0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.readOnly ? '仅供查看' : widget.orderStatus ?? '订单沟通',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF00B578)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_chat_unread_outlined,
              size: 34,
              color: Color(0xFF1D6FE9),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无沟通消息',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.readOnly ? '订单已结单，聊天记录仅供查看' : '发送消息或点击下方快捷短语开始沟通',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
        ],
      ),
    ),
  );

  Widget _buildQuickPhrases() => SizedBox(
    height: 40,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final phrase in const [
            '货物已准备好',
            '起降点已清空',
            '请问大概多久起飞？',
            '到达后请电话联系我',
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    _textController.value = TextEditingValue(
                      text: phrase,
                      selection: TextSelection.collapsed(offset: phrase.length),
                    );
                    _inputFocus.requestFocus();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      phrase,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  String _otherName() {
    return widget.sessionName ?? '';
  }
}
