import 'http_client.dart';
import 'generated/openapi_paths.dart';
import '../models/result_model.dart';
import '../models/session_vo.dart';
import '../models/task_chat_session_vo.dart';
import '../models/message_vo.dart';

class ChatApi {
  final HttpClient _client;

  ChatApi(this._client);

  // ==================== 会话 ====================

  Future<Result<List<SessionVo>>> listSessions() async {
    final response = await _client.dio.get(ApiPaths.chatSessionList);
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
    String? taskNum,
    int? applicationId,
  }) async {
    // 订单内会话绑定（ADR-0003 决定 1）：同 taskNum + 飞手由服务端去重。
    final body = <String, dynamic>{
      'name': name,
      'type': type,
      'userIds': userIds,
    };
    if (taskNum != null) body['taskNum'] = taskNum;
    if (applicationId != null) body['applicationId'] = applicationId;
    final response =
        await _client.dio.post(ApiPaths.chatSessionCreate, data: body);
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      return Result(
        success: true,
        code: 200,
        data: SessionVo.fromJson(data['data'] as Map<String, dynamic>),
      );
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  /// 任务内嵌会话聚合（GET /task/{taskNum}/chat-sessions）：
  /// 返回该任务下与各意向飞手的一对一会话（含 applicationId、未读数、最后一条消息）。
  Future<Result<List<TaskChatSessionVo>>> listTaskChatSessions(
      String taskNum) async {
    final response =
        await _client.dio.get(ApiPaths.taskChatSessionsPath(taskNum));
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => TaskChatSessionVo.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(
      success: false,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  // ==================== 消息 ====================

  Future<Result<List<MessageVo>>> getMessages(int sessionId) async {
    final response = await _client.dio.get(ApiPaths.chatMessageMessagesPath(sessionId));
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
    required int sessionId,
    required String content,
  }) async {
    final response = await _client.dio.post(ApiPaths.chatMessageSend, data: {
      'sessionId': sessionId,
      'content': content,
    });
    final data = response.data as Map<String, dynamic>;
    return Result(success: data['success'] == true, code: data['code'], message: data['message'] as String?);
  }

  /// 获取每个会话的未读消息数
  Future<Result<Map<int, int>>> getUnreadCount() async {
    final response = await _client.dio.get(ApiPaths.chatMessageUnreadCount);
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      final raw = data['data'] as Map<String, dynamic>;
      final map = raw.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      return Result(success: true, code: 200, data: map);
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }
}
