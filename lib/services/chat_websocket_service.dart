import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../config/api_config.dart';
import '../models/message_vo.dart';

enum ChatWebSocketStatus {
  disconnected,
  connecting,
  connected,
  failed,
  /// 被新登录顶掉（close code 4001，Q12=A 强制单设备在线）：
  /// 停止自动重连，等待用户手动重连。
  superseded,
}

/// 聊天长连接的传输抽象：默认走 dart:io WebSocket，
/// 测试可注入假实现驱动连接/断开/消息事件。
abstract interface class ChatSocket {
  Stream<dynamic> get stream;

  Duration? get pingInterval;

  set pingInterval(Duration? interval);

  /// 连接关闭码/原因（关闭后可读，来自服务端 close 帧）
  int? get closeCode;

  String? get closeReason;

  void send(dynamic data);

  Future<void> close([int? code, String? reason]);
}

class IoChatSocket implements ChatSocket {
  IoChatSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get stream => _socket;

  @override
  Duration? get pingInterval => _socket.pingInterval;

  @override
  set pingInterval(Duration? interval) => _socket.pingInterval = interval;

  @override
  int? get closeCode => _socket.closeCode;

  @override
  String? get closeReason => _socket.closeReason;

  @override
  void send(dynamic data) => _socket.add(data);

  @override
  Future<void> close([int? code, String? reason]) =>
      _socket.close(code, reason);
}

/// 建立聊天 WS 连接的工厂（t3 鉴权协议：握手头 Authorization: Bearer）。
typedef ChatSocketFactory =
    Future<ChatSocket> Function(Uri uri, Map<String, String> headers);

/// 主动刷新会话 token 的回调（t28：握手 403 自愈）。
/// 实现方应调用 /user/refresh 并持久化新 token，
/// 返回 refreshed / rejected（会话彻底失效）/ unreachable（网络性失败）。
typedef ChatSessionRefresher = Future<TokenRefreshOutcome> Function();

Future<ChatSocket> ioChatSocketConnect(
  Uri uri,
  Map<String, String> headers,
) async {
  final socket = await WebSocket.connect(uri.toString(), headers: headers);
  return IoChatSocket(socket);
}

/// 聊天实时长连接（/ws/{sid}）：
/// - 握手携带 `Authorization: Bearer <accessToken>`（t3 定稿，JWT.userId 必须等于 sid）；
/// - 断线（非主动断开）按指数退避自动重连（1s 起、30s 封顶）；
/// - 连接存活期间由 WebSocket 协议层心跳（pingInterval）探测死链；
/// - 重连成功后进入推送优先补拉：先等 3s 收服务端离线推送（isOffline 信封），
///   窗口内无任何下行才发出 resync 信号回落 REST 补拉（t28①）；
/// - 握手被拒（非 101 升级响应，即 403 鉴权拒绝）→ 走 refreshSession 刷新，
///   成功携新 token 重连、rejected 触发 onSessionInvalid 本地登出、
///   unreachable 维持退避；刷新后仍被拒同样登出（t28②）；
/// - 收到 4001（被新登录顶掉，Q12=A 强制单设备在线）→ 停止自动重连并
///   上抛 superseded 状态，重新进入消息页 ensureConnected 手动重连（t28③）；
/// - 登出调用 disconnect() 后不再重连，避免继续接收前一账号消息（P1-3）。
class ChatWebSocketService {
  ChatWebSocketService(
    this._tokenStorage, {
    ChatSocketFactory? socketFactory,
    this.refreshSession,
    this.onSessionInvalid,
  }) : _socketFactory = socketFactory ?? ioChatSocketConnect;

  /// 心跳（协议层 ping/pong）间隔
  static const Duration heartbeatInterval = Duration(seconds: 30);

  /// 重连退避参数：1s 起步、指数翻倍、30s 封顶
  static const Duration reconnectBaseDelay = Duration(seconds: 1);
  static const Duration reconnectMaxDelay = Duration(seconds: 30);

  /// 推送优先补拉的静默等待窗（t28①）：重连成功后先等此时长收服务端
  /// 自动推送的离线消息，窗口内无任何下行才回落 REST 补拉信号。
  static const Duration resyncGracePeriod = Duration(seconds: 3);

  /// 顶号关闭码（t28③，契约冻结：仅聊天通道）
  static const int supersededCloseCode = 4001;
  static const String supersededCloseReason = 'replaced by newer login';

  final TokenStorage _tokenStorage;
  final ChatSocketFactory _socketFactory;

  /// 握手被拒（403）后的主动刷新回调（t28②）；未注入则退回普通退避。
  final ChatSessionRefresher? refreshSession;

  /// 刷新仍无法恢复会话时的兜底回调：触发本地登出（sessionExpired 链）。
  final void Function()? onSessionInvalid;

  final _messagesController = StreamController<MessageVo>.broadcast();
  final _statusController = StreamController<ChatWebSocketStatus>.broadcast(
    sync: true,
  );
  final _resyncController = StreamController<void>.broadcast();

  ChatSocket? _socket;
  int? _activeUserId;
  bool _manuallyClosed = false;
  bool _connecting = false;
  bool _everConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _resyncGraceTimer;
  bool _downlinkSinceReconnect = false;
  int _handshakeAuthRetries = 0;

  Stream<MessageVo> get messages => _messagesController.stream;
  Stream<ChatWebSocketStatus> get status => _statusController.stream;

  /// 断线重连成功且静默后的补拉信号（推送优先，REST 仅兜底）
  Stream<void> get resync => _resyncController.stream;

  bool get isConnected => _socket != null;

  Future<void> ensureConnected(int userId) async {
    if (userId <= 0) return;
    if (_activeUserId == userId && (_socket != null || _connecting)) return;
    if (_activeUserId == userId && _reconnectTimer != null) return;

    // 切换目标用户或重新开始连接：清理旧链路（不计为手动断开的最终态）。
    await _teardown();
    _manuallyClosed = false;
    _activeUserId = userId;
    _everConnected = false;
    _reconnectAttempts = 0;
    _handshakeAuthRetries = 0;
    await _connect();
  }

  /// 主动断开（登出/切换账号）：取消重连计划并关闭连接。
  Future<void> disconnect() async {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _activeUserId = null;
    _everConnected = false;
    _reconnectAttempts = 0;
    await _teardown();
    _statusController.add(ChatWebSocketStatus.disconnected);
  }

  void dispose() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _teardown();
    _messagesController.close();
    _statusController.close();
    _resyncController.close();
  }

  Future<void> _teardown() async {
    _connecting = false;
    _resyncGraceTimer?.cancel();
    _resyncGraceTimer = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close(WebSocketStatus.normalClosure, 'chat disconnect');
      } catch (_) {
        // 关闭旧链路失败可忽略：连接对象随后被丢弃。
      }
    }
  }

  Future<void> _connect() async {
    final userId = _activeUserId;
    if (userId == null || _manuallyClosed || _connecting) return;

    final token = _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      // 无 token 无法通过 t3 握手鉴权，不发起连接也不重连；
      // 登录成功后由认证生命周期再次触发 ensureConnected。
      _statusController.add(ChatWebSocketStatus.failed);
      return;
    }

    _connecting = true;
    _statusController.add(ChatWebSocketStatus.connecting);
    try {
      final uri = _resolveChatWebSocketUrl(userId);
      final socket = await _socketFactory(uri, {
        'Authorization': 'Bearer $token',
      });
      // 连接建立期间可能已登出/切换账号：丢弃过期链路。
      if (_manuallyClosed || _activeUserId != userId) {
        await socket.close(WebSocketStatus.normalClosure, 'stale connect');
        return;
      }
      _socket = socket;
      _connecting = false;
      _reconnectAttempts = 0;
      _handshakeAuthRetries = 0;
      socket.pingInterval = heartbeatInterval;
      socket.stream.listen(
        (data) {
          // 任何下行（含离线推送）都视为服务端活跃，取消 REST 补拉兜底。
          _downlinkSinceReconnect = true;
          _resyncGraceTimer?.cancel();
          _resyncGraceTimer = null;
          _handlePayload(data);
        },
        onDone: _handleClosed,
        onError: (_) => _handleFailure(),
        cancelOnError: true,
      );
      _statusController.add(ChatWebSocketStatus.connected);
      if (_everConnected) {
        // 断线重连成功（t28①）：推送优先——先等 3s 收服务端离线推送，
        // 窗口内无任何下行才回落 REST 补拉信号。
        _downlinkSinceReconnect = false;
        _resyncGraceTimer?.cancel();
        _resyncGraceTimer = Timer(resyncGracePeriod, () {
          _resyncGraceTimer = null;
          if (!_downlinkSinceReconnect && !_manuallyClosed) {
            _resyncController.add(null);
          }
        });
      }
      _everConnected = true;
    } catch (error) {
      _connecting = false;
      _socket = null;
      _statusController.add(ChatWebSocketStatus.failed);
      if (error is WebSocketException) {
        // 服务端可达但拒绝升级（403 鉴权拒绝走此路径，t28②）。
        await _handleHandshakeRejected();
        return;
      }
      _scheduleReconnect();
    }
  }

  /// 握手被拒（403）的自愈：先刷新 token，成功携新 token 重连；
  /// rejected 触发本地登出；unreachable 维持退避；刷新后仍被拒同样登出。
  Future<void> _handleHandshakeRejected() async {
    if (_manuallyClosed || _activeUserId == null) return;
    final refresher = refreshSession;
    if (refresher == null) {
      // 未注入刷新能力：退回普通退避兜底（向后兼容）。
      _scheduleReconnect();
      return;
    }
    if (_handshakeAuthRetries >= 1) {
      // 刷新拿到新 token 后仍被拒：非 token 过期问题，无法自愈 → 登出。
      onSessionInvalid?.call();
      return;
    }
    _handshakeAuthRetries += 1;
    final outcome = await refresher();
    if (_manuallyClosed || _activeUserId == null) return;
    if (outcome == TokenRefreshOutcome.refreshed) {
      await _connect();
      return;
    }
    if (outcome == TokenRefreshOutcome.rejected) {
      onSessionInvalid?.call();
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manuallyClosed || _activeUserId == null || _reconnectTimer != null) {
      return;
    }
    final delay = _reconnectDelay(_reconnectAttempts);
    _reconnectAttempts += 1;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _connect();
    });
  }

  /// 指数退避：1s, 2s, 4s, 8s, 16s, 30s, 30s...
  static Duration _reconnectDelay(int attempts) {
    final multiplier = pow(2, min(attempts, 5)).toInt();
    final delay = reconnectBaseDelay * multiplier;
    return delay > reconnectMaxDelay ? reconnectMaxDelay : delay;
  }

  void _handleClosed() {
    final closed = _socket;
    _socket = null;
    _resyncGraceTimer?.cancel();
    _resyncGraceTimer = null;
    if (_manuallyClosed) return;
    if (closed?.closeCode == supersededCloseCode) {
      // 被新登录顶掉（Q12=A 强制单设备在线）：停止自动重连，
      // 上抛 superseded 状态供 UI 提示；重新进入消息页 ensureConnected
      // 即可手动重连。
      _activeUserId = null;
      _everConnected = false;
      _reconnectAttempts = 0;
      _statusController.add(ChatWebSocketStatus.superseded);
      return;
    }
    _statusController.add(ChatWebSocketStatus.disconnected);
    _scheduleReconnect();
  }

  void _handleFailure() {
    _socket = null;
    _resyncGraceTimer?.cancel();
    _resyncGraceTimer = null;
    if (_manuallyClosed) return;
    _statusController.add(ChatWebSocketStatus.failed);
    _scheduleReconnect();
  }

  Uri _resolveChatWebSocketUrl(int userId) {
    final serverUrl = ApiConfig.resolveBaseUrl(_tokenStorage.getServerUrl());

    final uri = Uri.parse(serverUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final basePath = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    final wsPath = basePath.isEmpty || basePath == '/'
        ? '/ws/$userId'
        : '$basePath/ws/$userId';

    return uri.replace(scheme: wsScheme, path: wsPath, query: '');
  }

  void _handlePayload(dynamic payload) {
    if (payload is! String) return;
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return;
      final message = MessageVo.fromJson(json);
      if (message.msgId.isNotEmpty && message.sessionId > 0) {
        _messagesController.add(message);
      }
    } catch (_) {
      // Ignore malformed realtime payloads; HTTP history remains the fallback.
    }
  }
}
