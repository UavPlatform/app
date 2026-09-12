// t14 测试公共设施：JWT 构造、假 WS socket、可编排的连接工厂、dio 桩适配器。

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:uav_pilot_app/services/chat_websocket_service.dart';
import 'package:uav_pilot_app/services/live_player.dart';

/// 构造测试用 JWT（JwtDecoder 仅解析 payload 的 userId/username/role）。
String makeJwt({int userId = 1, String username = 'tester', int role = 0}) {
  String encode(Map<String, dynamic> json) => base64Url
      .encode(utf8.encode(jsonEncode(json)))
      .replaceAll('=', '');
  final header = encode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encode({
    'userId': userId,
    'username': username,
    'role': role,
    'exp': 4102444800,
  });
  return '$header.$payload.signature';
}

/// 聊天 WS 的假传输实现：记录 pingInterval/发送/关闭，
/// 并允许测试注入服务端行为（断开/错误/推送消息/关闭码）。
class FakeChatSocket implements ChatSocket {
  final _incoming = StreamController<dynamic>.broadcast();
  final sent = <dynamic>[];
  int closeCount = 0;
  Duration? _pingInterval;

  @override
  int? closeCode;

  @override
  String? closeReason;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  Duration? get pingInterval => _pingInterval;

  @override
  set pingInterval(Duration? interval) => _pingInterval = interval;

  @override
  void send(dynamic data) => sent.add(data);

  @override
  Future<void> close([int? code, String? reason]) async {
    closeCount += 1;
  }

  /// 模拟服务端正常关闭连接（触发 onDone）。
  void serverCloses() {
    _incoming.close();
  }

  /// 模拟服务端连接错误（触发 onError）。
  void serverErrors() {
    _incoming.addError(StateError('boom'));
  }

  /// 模拟服务端推送一条实时消息。
  void pushMessage(Map<String, dynamic> json) {
    _incoming.add(jsonEncode(json));
  }
}

/// 一次连接请求的记录。
typedef RecordedConnect = ({Uri uri, Map<String, String> headers});

/// 可编排的连接工厂：按入队顺序返回假 socket 或抛错（模拟网络失败）。
class ScriptedSocketFactory {
  final calls = <RecordedConnect>[];
  final _outcomes = Queue<Object>();

  void enqueueSocket(FakeChatSocket socket) => _outcomes.add(socket);

  void enqueueError(Object error) => _outcomes.add(error);

  Future<ChatSocket> call(Uri uri, Map<String, String> headers) {
    calls.add((uri: uri, headers: headers));
    if (_outcomes.isEmpty) {
      return Future.error(StateError('unexpected connect'));
    }
    final outcome = _outcomes.removeFirst();
    if (outcome is FakeChatSocket) {
      return Future<ChatSocket>.value(outcome);
    }
    final error = outcome;
    return Future.error(error);
  }
}

/// dio 桩适配器：拦截全部请求，按测试脚本返回响应。
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// 构造 JSON 响应体。
ResponseBody jsonResponse(int status, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
  );
}

/// 直播播放器假引擎（t38 生命周期测试用）：
/// 记录 enter/attach/exit 调用，支持手动注入引擎事件与进房失败。
class FakeTrtcEngine implements TrtcEngine {
  final _events = StreamController<TrtcEvent>.broadcast();
  final entered = <LiveStreamSession>[];
  final attachedViewIds = <int>[];
  int detachCalls = 0;
  int exitCalls = 0;
  bool failEnter = false;
  Object? enterError;

  @override
  Stream<TrtcEvent> get events => _events.stream;

  @override
  Future<void> enter(LiveStreamSession session) async {
    if (failEnter) {
      throw enterError ?? StateError('enter failed');
    }
    entered.add(session);
  }

  @override
  Future<void> attachRemoteView(int viewId) async {
    attachedViewIds.add(viewId);
  }

  @override
  Future<void> detachRemoteView() async {
    detachCalls += 1;
  }

  @override
  Future<void> exit() async {
    exitCalls += 1;
  }

  void emitRemoteVideoUnavailable() {
    _events.add(const TrtcEvent(TrtcEventKind.remoteVideoUnavailable));
  }

  void emitExited() {
    _events.add(const TrtcEvent(TrtcEventKind.exited));
  }
}
