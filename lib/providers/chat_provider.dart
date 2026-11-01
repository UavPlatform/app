import '../utils/failure_message.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/chat_api.dart';
import '../api/generated/openapi_paths.dart';
import '../api/http_client.dart';
import '../models/session_vo.dart';
import '../models/message_vo.dart';
import '../models/task_chat_session_vo.dart';
import '../services/chat_websocket_service.dart';
import 'auth_provider.dart';
import 'waybill_draft_provider.dart';

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.watch(httpClientProvider)),
);

final chatWebSocketServiceProvider = Provider<ChatWebSocketService>((ref) {
  final service = ChatWebSocketService(
    ref.watch(tokenStorageProvider),
    // t28②：握手 403 自愈——主动刷新 token，rejected 走 sessionExpired 登出链
    refreshSession: () => ref.read(httpClientProvider).refreshTokens(),
    onSessionInvalid: () =>
        unawaited(ref.read(authProvider.notifier).logout(sessionExpired: true)),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// 聊天连接状态流（t28③：superseded 状态供 UI 提示顶号）。
final chatStatusProvider = StreamProvider<ChatWebSocketStatus>(
  (ref) => ref.watch(chatWebSocketServiceProvider).status,
);

/// 认证驱动的实时链路生命周期（P1-3）：
/// - 登录成功后自动建立聊天 WS（含应用启动时已持有 token 的场景）；
/// - 登出/401 失效（unauthenticated）立即断开 WS，不再接收前一账号消息，
///   并清理前一账号的会话列表与未读角标。
/// 由 MyApp watch 激活；仅响应认证态变化，不在构建期做清理副作用。
final chatRealtimeLifecycleProvider = Provider<void>((ref) {
  final service = ref.watch(chatWebSocketServiceProvider);

  ref.listen<AuthState>(authProvider, (prev, next) {
    final userId = int.tryParse(next.user?.userId ?? '') ?? 0;
    if (next.status == AuthStatus.authenticated && userId > 0) {
      unawaited(service.ensureConnected(userId));
    } else if (next.status == AuthStatus.unauthenticated) {
      unawaited(service.disconnect());
      ref.invalidate(sessionListProvider);
      ref.invalidate(messageListProvider);
    }
  });

  // 冷启动初始状态：已持有 token 则直接建立长连接。
  final auth = ref.read(authProvider);
  final userId = int.tryParse(auth.user?.userId ?? '') ?? 0;
  if (auth.status == AuthStatus.authenticated && userId > 0) {
    unawaited(service.ensureConnected(userId));
  }
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
  final HttpClient _httpClient;
  StreamSubscription<MessageVo>? _realtimeSub;
  StreamSubscription<void>? _resyncSub;
  final int viewerUserId;
  final Set<String> _seenMessageIds = {};

  SessionListNotifier(
    this._api,
    this._httpClient,
    Stream<MessageVo> messages,
    Stream<void> resync, {
    this.viewerUserId = 0,
  }) : super(const SessionListState()) {
    _realtimeSub = messages.listen(_applyRealtimeSummary);
    // WS 断线重连成功后补拉会话列表（P1-2）。
    _resyncSub = resync.listen((_) => load());
    load();
  }

  /// 进入会话时显式推进已读（t50，对齐 t49 后端契约）：
  /// POST /chat/Message/read?sessionId= → 服务端该会话 lastReadTime=now；
  /// 本地同步清零该会话未读，避免回到列表仍显示旧红点。
  Future<void> markSessionRead(int sessionId) async {
    try {
      final response = await _httpClient.dio.post(
        ApiPaths.chatMessageRead,
        queryParameters: ApiPaths.chatMessageReadQuery(sessionId: sessionId),
      );
      if (response.data is! Map || response.data['success'] != true) return;
    } catch (_) {
      // 已读推进失败不阻塞 UI（下次进入会话重试）
      return;
    }
    if (!mounted) return;
    final sessions = state.sessions
        .map((s) => s.id == sessionId ? s.copyWith(unreadCount: 0) : s)
        .toList();
    state = state.copyWith(sessions: sessions);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listSessions();
      if (!mounted) return;
      if (result.success && result.data != null) {
        final sessions = [...result.data!]
          ..sort((a, b) => b.sortTime.compareTo(a.sortTime));
        state = state.copyWith(loading: false, sessions: sessions);
      } else {
        state = state.copyWith(
          loading: false,
          error: resultFailureMessage(result, fallback: '消息暂时无法加载，请稍后刷新'),
        );
      }
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: failureMessage(error, fallback: '消息暂时无法加载，请稍后刷新'),
      );
    }
  }

  Future<SessionVo?> createDirectSession({
    required String name,
    required int userId,
    String? taskNum,
    int? applicationId,
  }) async {
    state = state.copyWith(creatingSession: true, error: null);
    try {
      final result = await _api.createSession(
        name: name,
        type: 0,
        userIds: [userId],
        taskNum: taskNum,
        applicationId: applicationId,
      );
      if (!mounted) return null;
      if (!result.success || result.data == null) {
        state = state.copyWith(
          creatingSession: false,
          error: resultFailureMessage(result, fallback: '创建会话失败'),
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
    } catch (error) {
      if (!mounted) return null;
      state = state.copyWith(
        creatingSession: false,
        error: failureMessage(error, fallback: '聊天会话创建未完成，请返回订单重试'),
      );
      return null;
    }
  }

  void _applyRealtimeSummary(MessageVo message) {
    if (!mounted) return;
    if (!_seenMessageIds.add(message.msgId)) return;
    if (_seenMessageIds.length > 1024) {
      _seenMessageIds.remove(_seenMessageIds.first);
    }
    if (!state.sessions.any((session) => session.id == message.sessionId)) {
      // The other participant can create the first session; discover it on push.
      unawaited(load());
      return;
    }
    final sessions = state.sessions.map((session) {
      if (session.id != message.sessionId) return session;
      return session.copyWith(
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        unreadCount:
            session.unreadCount + (message.fromUserId == viewerUserId ? 0 : 1),
      );
    }).toList()..sort((a, b) => b.sortTime.compareTo(a.sortTime));
    state = state.copyWith(sessions: sessions, loading: false);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _resyncSub?.cancel();
    super.dispose();
  }
}

final sessionListProvider =
    StateNotifierProvider<SessionListNotifier, SessionListState>((ref) {
      final service = ref.watch(chatWebSocketServiceProvider);
      return SessionListNotifier(
        ref.watch(chatApiProvider),
        ref.watch(httpClientProvider),
        service.messages,
        service.resync,
        viewerUserId:
            int.tryParse(
              ref.watch(authProvider.select((auth) => auth.user?.userId)) ?? '',
            ) ??
            0,
      );
    });

// ==================== 任务内嵌会话（订单详情） ====================

class TaskChatSessionsState {
  final List<TaskChatSessionVo> sessions;
  final bool loading;
  final String? error;

  const TaskChatSessionsState({
    this.sessions = const [],
    this.loading = true,
    this.error,
  });

  TaskChatSessionsState copyWith({
    List<TaskChatSessionVo>? sessions,
    bool? loading,
    String? error,
  }) {
    return TaskChatSessionsState(
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// GET /task/{taskNum}/chat-sessions：详情页据此判断应征项是否已有会话、
/// 展示订单内红点未读（进入会话读后重新 load 对齐服务端）。
class TaskChatSessionsNotifier extends StateNotifier<TaskChatSessionsState> {
  final ChatApi _api;
  final String taskNum;
  StreamSubscription<MessageVo>? _realtimeSub;
  StreamSubscription<void>? _resyncSub;
  Timer? _refreshDebounce;
  Future<void>? _pendingLoad;

  TaskChatSessionsNotifier(
    this._api,
    this.taskNum,
    Stream<MessageVo> messages,
    Stream<void> resync,
  ) : super(const TaskChatSessionsState()) {
    _realtimeSub = messages.listen((_) {
      // A new session is not yet in this list, so refresh even for unknown IDs.
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(const Duration(milliseconds: 250), () async {
        _refreshDebounce = null;
        await _pendingLoad;
        if (mounted) await load(silent: true);
      });
    });
    _resyncSub = resync.listen((_) => load(silent: true));
    load();
  }

  Future<void> load({bool silent = false}) {
    return _pendingLoad ??= _load(
      silent: silent,
    ).whenComplete(() => _pendingLoad = null);
  }

  Future<void> _load({required bool silent}) async {
    state = state.copyWith(
      loading: !silent && state.sessions.isEmpty,
      error: null,
    );
    try {
      final result = await _api.listTaskChatSessions(taskNum);
      if (!mounted) return;
      if (result.success && result.data != null) {
        state = state.copyWith(loading: false, sessions: result.data!);
      } else {
        state = state.copyWith(
          loading: false,
          error: resultFailureMessage(result, fallback: '获取任务会话失败'),
        );
      }
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: failureMessage(error, fallback: '任务会话暂时无法加载，请稍后刷新'),
      );
    }
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    _realtimeSub?.cancel();
    _resyncSub?.cancel();
    super.dispose();
  }
}

/// 任务内嵌会话：autoDispose，每次进入详情页重新对齐服务端未读与会话归属。
final taskChatSessionsProvider = StateNotifierProvider.autoDispose
    .family<TaskChatSessionsNotifier, TaskChatSessionsState, String>((
      ref,
      taskNum,
    ) {
      final service = ref.watch(chatWebSocketServiceProvider);
      return TaskChatSessionsNotifier(
        ref.watch(chatApiProvider),
        taskNum,
        service.messages,
        service.resync,
      );
    });

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
  StreamSubscription<void>? _resyncSub;
  Future<void>? _pendingLoad;
  final Map<String, MessageVo> _receivedDuringLoad = {};

  MessageListNotifier(
    this._api,
    this.sessionId,
    Stream<MessageVo> messages,
    Stream<void> resync,
  ) : super(const MessageListState()) {
    _realtimeSub = messages.listen(_appendRealtimeMessage);
    // WS 断线重连成功后补拉当前会话历史，弥合离线期间的消息空洞（P1-2）。
    _resyncSub = resync.listen((_) => load(silent: true));
    load();
  }

  Future<void> load({bool silent = false}) {
    return _pendingLoad ??= _load(
      silent: silent,
    ).whenComplete(() => _pendingLoad = null);
  }

  Future<void> _load({required bool silent}) async {
    _receivedDuringLoad.clear();
    state = state.copyWith(
      loading: !silent && state.messages.isEmpty,
      error: null,
    );
    try {
      final result = await _api.getMessages(sessionId);
      if (!mounted) return;
      if (result.success && result.data != null) {
        final byId = {
          for (final message in result.data!) message.msgId: message,
        };
        // A slow history response must not erase a newer WebSocket message.
        byId.addAll(_receivedDuringLoad);
        final messages = byId.values.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        state = state.copyWith(loading: false, messages: messages);
      } else {
        state = state.copyWith(
          loading: false,
          error: resultFailureMessage(result, fallback: '消息暂时无法加载，请稍后刷新'),
        );
      }
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: failureMessage(error, fallback: '消息暂时无法加载，请稍后刷新'),
      );
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
        // Wait for any older snapshot before fetching our just-sent message.
        await _pendingLoad;
        if (!mounted) return false;
        await load(silent: true);
        if (!mounted) return false;
        state = state.copyWith(sending: false);
        return true;
      }
      if (!mounted) return false;
      state = state.copyWith(
        sending: false,
        error: resultFailureMessage(result, fallback: '消息发送未完成，请稍后重试'),
      );
      return false;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        sending: false,
        error: failureMessage(error, fallback: '消息发送未完成，请稍后重试'),
      );
      return false;
    }
  }

  void _appendRealtimeMessage(MessageVo message) {
    if (!mounted) return;
    if (message.sessionId != sessionId) return;
    if (_pendingLoad != null || state.loading) {
      _receivedDuringLoad[message.msgId] = message;
    }
    final messages = [
      ...state.messages.where((item) => item.msgId != message.msgId),
      message,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = state.copyWith(messages: messages, loading: false, error: null);
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _resyncSub?.cancel();
    super.dispose();
  }
}

final messageListProvider = StateNotifierProvider.autoDispose
    .family<MessageListNotifier, MessageListState, int>((ref, sessionId) {
      ref.watch(waybillDraftScopeProvider);
      final service = ref.watch(chatWebSocketServiceProvider);
      return MessageListNotifier(
        ref.watch(chatApiProvider),
        sessionId,
        service.messages,
        service.resync,
      );
    });

// ==================== 重连补拉与按单未读 ====================

/// WS 断线重连成功的补拉信号（供 FutureProvider 等订阅刷新）。
final chatResyncProvider = StreamProvider<void>(
  (ref) => ref.watch(chatWebSocketServiceProvider).resync,
);
