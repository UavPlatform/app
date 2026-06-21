import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/message_vo.dart';
import 'token_storage.dart';

enum ChatWebSocketStatus { disconnected, connecting, connected, failed }

class ChatWebSocketService {
  ChatWebSocketService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  final _messagesController = StreamController<MessageVo>.broadcast();
  final _statusController = StreamController<ChatWebSocketStatus>.broadcast(
    sync: true,
  );

  WebSocket? _socket;
  int? _connectedUserId;
  bool _manuallyClosed = false;

  Stream<MessageVo> get messages => _messagesController.stream;
  Stream<ChatWebSocketStatus> get status => _statusController.stream;

  Future<void> ensureConnected(int userId) async {
    if (userId <= 0) return;
    if (_socket != null && _connectedUserId == userId) return;

    await disconnect();
    _manuallyClosed = false;
    _connectedUserId = userId;
    _statusController.add(ChatWebSocketStatus.connecting);

    try {
      final url = _resolveChatWebSocketUrl(userId);
      final socket = await WebSocket.connect(url);
      _socket = socket;
      _statusController.add(ChatWebSocketStatus.connected);

      socket.listen(
        _handlePayload,
        onDone: _handleClosed,
        onError: (_) => _handleFailure(),
        cancelOnError: true,
      );
    } catch (_) {
      _socket = null;
      _connectedUserId = null;
      _statusController.add(ChatWebSocketStatus.failed);
    }
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    final socket = _socket;
    _socket = null;
    _connectedUserId = null;
    if (socket != null) {
      await socket.close(WebSocketStatus.normalClosure, 'chat disconnect');
    }
    _statusController.add(ChatWebSocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _messagesController.close();
    _statusController.close();
  }

  String _resolveChatWebSocketUrl(int userId) {
    final serverUrl = _tokenStorage.getServerUrl();
    if (serverUrl == null || serverUrl.isEmpty) {
      throw StateError('未配置服务器地址');
    }

    final uri = Uri.parse(serverUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final basePath = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    final wsPath = basePath.isEmpty || basePath == '/'
        ? '/ws/$userId'
        : '$basePath/ws/$userId';

    return uri.replace(scheme: wsScheme, path: wsPath, query: '').toString();
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

  void _handleClosed() {
    _socket = null;
    _connectedUserId = null;
    if (!_manuallyClosed) {
      _statusController.add(ChatWebSocketStatus.disconnected);
    }
  }

  void _handleFailure() {
    _socket = null;
    _connectedUserId = null;
    _statusController.add(ChatWebSocketStatus.failed);
  }
}
