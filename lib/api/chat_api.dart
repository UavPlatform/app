import 'http_client.dart';
import '../models/result_model.dart';
import '../models/session_vo.dart';
import '../models/message_vo.dart';

class ChatApi {
  final HttpClient _client;

  ChatApi(this._client);

  // ==================== 会话 ====================

  Future<Result<List<SessionVo>>> listSessions() async {
    final response = await _client.dio.get('/chat/session/list');
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => SessionVo.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  Future<Result<SessionVo>> createSession({
    required String name,
    required int type,
    required List<int> userIds,
  }) async {
    final response = await _client.dio.post('/chat/session/create', data: {
      'name': name,
      'type': type,
      'userIds': userIds,
    });
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      return Result(
        success: true,
        code: 200,
        data: SessionVo.fromJson(data['data'] as Map<String, dynamic>),
      );
    }
    return Result(success: data['success'] == true, code: data['code'], message: data['message'] as String?);
  }

  // ==================== 消息 ====================

  Future<Result<List<MessageVo>>> getMessages(int sessionId) async {
    final response = await _client.dio.get('/chat/Message/messages/$sessionId');
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => MessageVo.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  Future<Result<void>> sendMessage({
    required int fromUserId,
    required int sessionId,
    required String content,
  }) async {
    final response = await _client.dio.post('/chat/Message/send', data: {
      'fromUserId': fromUserId,
      'sessionId': sessionId,
      'content': content,
    });
    final data = response.data as Map<String, dynamic>;
    return Result(success: data['success'] == true, code: data['code'], message: data['message'] as String?);
  }
}
