import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/chat_api.dart';
import '../models/session_vo.dart';
import '../models/message_vo.dart';
import 'auth_provider.dart';

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(httpClientProvider)),
);

// ==================== 会话列表 ====================

class SessionListState {
  final List<SessionVo> sessions;
  final bool loading;
  final String? error;

  const SessionListState({this.sessions = const [], this.loading = true, this.error});

  SessionListState copyWith({List<SessionVo>? sessions, bool? loading, String? error}) {
    return SessionListState(
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class SessionListNotifier extends StateNotifier<SessionListState> {
  final ChatApi _api;

  SessionListNotifier(this._api) : super(const SessionListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listSessions();
      if (result.success && result.data != null) {
        state = state.copyWith(loading: false, sessions: result.data!);
      } else {
        state = state.copyWith(loading: false, error: result.message ?? '加载失败');
      }
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, SessionListState>(
  (ref) => SessionListNotifier(ref.watch(chatApiProvider)),
);

// ==================== 消息列表（单个会话） ====================

class MessageListState {
  final List<MessageVo> messages;
  final bool loading;
  final String? error;

  const MessageListState({this.messages = const [], this.loading = true, this.error});

  MessageListState copyWith({List<MessageVo>? messages, bool? loading, String? error}) {
    return MessageListState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class MessageListNotifier extends StateNotifier<MessageListState> {
  final ChatApi _api;
  final int sessionId;

  MessageListNotifier(this._api, this.sessionId) : super(const MessageListState()) {
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

  Future<bool> sendMessage({required int fromUserId, required String content}) async {
    try {
      final result = await _api.sendMessage(
        fromUserId: fromUserId,
        sessionId: sessionId,
        content: content,
      );
      if (result.success) {
        await load();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final messageListProvider = StateNotifierProvider.family<MessageListNotifier,
    MessageListState, int>(
  (ref, sessionId) =>
      MessageListNotifier(ref.watch(chatApiProvider), sessionId),
);
