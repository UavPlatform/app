import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/chat_api.dart';
import '../models/session_vo.dart';
import '../models/message_vo.dart';
import '../services/chat_websocket_service.dart';
import 'auth_provider.dart';

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(httpClientProvider)),
);

final chatWebSocketServiceProvider = Provider<ChatWebSocketService>((ref) {
  final service = ChatWebSocketService();
  ref.onDispose(service.dispose);
  return service;
});

// ==================== 会话列表 ====================

class SessionListState {
  final List<SessionVo> sessions;
  final bool loading;
  final bool creatingSession;
  final String? error;

  const SessionListState({
    this.sessions = const [],
    this.loading = true,
    this.creatingSession = false,
    this.error,
  });

  SessionListState copyWith({
    List<SessionVo>? sessions,
    bool? loading,
    bool? creatingSession,
    String? error,
  }) {
    return SessionListState(
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      creatingSession: creatingSession ?? this.creatingSession,
      error: error,
    );
  }
}

class SessionListNotifier extends StateNotifier<SessionListState> {
  final ChatApi _api;
  StreamSubscription<MessageVo>? _realtimeSub;

  SessionListNotifier(this._api, Stream<MessageVo> messages)
    : super(const SessionListState()) {
    _realtimeSub = messages.listen(_applyRealtimeSummary);
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listSessions();
      if (result.success && result.data != null) {
        final sessions = [...result.data!]
          ..sort((a, b) => b.sortTime.compareTo(a.sortTime));
        state = state.copyWith(loading: false, sessions: sessions);
      } else {
        state = state.copyWith(loading: false, error: result.message ?? '加载失败');
      }
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  Future<SessionVo?> createDirectSession({
    required String name,
    required int userId,
  }) async {
    state = state.copyWith(creatingSession: true, error: null);
    try {
      final result = await _api.createSession(
        name: name,
        type: 0,
        userIds: [userId],
      );
      if (!result.success || result.data == null) {
        state = state.copyWith(
          creatingSession: false,
          error: result.message ?? '创建会话失败',
        );
        return null;
      }

      final session = result.data!;
      final sessions = [
        session,
        ...state.sessions.where((item) => item.id != session.id),
      ]..sort((a, b) => b.sortTime.compareTo(a.sortTime));
      state = state.copyWith(
        creatingSession: false,
        sessions: sessions,
        error: null,
      );
      return session;
    } catch (_) {
      state = state.copyWith(creatingSession: false, error: '创建会话失败');
      return null;
    }
  }

  void _applyRealtimeSummary(MessageVo message) {
    final sessions = state.sessions.map((session) {
      if (session.id != message.sessionId) return session;
      return session.copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        unreadCount: session.unreadCount + 1,
      );
    }).toList()..sort((a, b) => b.sortTime.compareTo(a.sortTime));
    state = state.copyWith(sessions: sessions, loading: false);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, SessionListState>(
      (ref) => SessionListNotifier(
        ref.watch(chatApiProvider),
        ref.watch(chatWebSocketServiceProvider).messages,
      ),
    );

// ==================== 消息列表（单个会话） ====================

class MessageListState {
  final List<MessageVo> messages;
  final bool loading;
  final bool sending;
  final String? error;

  const MessageListState({
    this.messages = const [],
    this.loading = true,
    this.sending = false,
    this.error,
  });

  MessageListState copyWith({
    List<MessageVo>? messages,
    bool? loading,
    bool? sending,
    String? error,
  }) {
    return MessageListState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: error,
    );
  }
}

class MessageListNotifier extends StateNotifier<MessageListState> {
  final ChatApi _api;
  final int sessionId;
  StreamSubscription<MessageVo>? _realtimeSub;

  MessageListNotifier(this._api, this.sessionId, Stream<MessageVo> messages)
    : super(const MessageListState()) {
    _realtimeSub = messages.listen(_appendRealtimeMessage);
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.getMessages(sessionId);
      if (result.success && result.data != null) {
        state = state.copyWith(loading: false, messages: result.data!);
      } else {
        state = state.copyWith(loading: false, error: result.message ?? '加载失败');
      }
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  Future<bool> sendMessage({required String content}) async {
    if (state.sending) return false;
    state = state.copyWith(sending: true, error: null);
    try {
      final result = await _api.sendMessage(
        sessionId: sessionId,
        content: content,
      );
      if (result.success) {
        await load();
        state = state.copyWith(sending: false);
        return true;
      }
      state = state.copyWith(sending: false, error: result.message ?? '发送失败');
      return false;
    } catch (_) {
      state = state.copyWith(sending: false, error: '发送失败');
      return false;
    }
  }

  void _appendRealtimeMessage(MessageVo message) {
    if (message.sessionId != sessionId) return;
    final messages = [
      ...state.messages.where((item) => item.msgId != message.msgId),
      message,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = state.copyWith(messages: messages, loading: false, error: null);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

final messageListProvider =
    StateNotifierProvider.family<MessageListNotifier, MessageListState, int>(
      (ref, sessionId) => MessageListNotifier(
        ref.watch(chatApiProvider),
        sessionId,
        ref.watch(chatWebSocketServiceProvider).messages,
      ),
    );

// ==================== 全局未读消息数 ====================

final totalUnreadCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(chatApiProvider);
  final result = await api.getUnreadCount();
  if (result.success && result.data != null) {
    return result.data!.values.fold<int>(0, (sum, v) => sum + v);
  }
  return 0;
});
