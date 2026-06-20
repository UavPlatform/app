import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final int sessionId;
  final String? sessionName;
  const ChatDetailPage({super.key, required this.sessionId, this.sessionName});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final userId = int.tryParse(ref.read(authProvider).user?.userId ?? '') ?? 0;
    ref.read(messageListProvider(widget.sessionId).notifier).sendMessage(
          fromUserId: userId,
          content: text,
        );
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageListProvider(widget.sessionId));
    final uid = int.tryParse(ref.read(authProvider).user?.userId ?? '') ?? 0;
    final title = widget.sessionName ?? '聊天';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[state.messages.length - 1 - index];
                      final isMine = msg.fromUserId == uid;
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMine)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                                  child: Text(
                                    _otherName(),
                                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isMine ? AppColors.primary : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(color: isMine ? Colors.white : AppColors.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: '输入消息...', border: InputBorder.none),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _send,
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
