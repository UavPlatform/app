import '../api/generated/openapi_models.dart';

/// 任务内嵌会话（GET /task/{taskNum}/chat-sessions）：
/// 任务属主按 taskNum 聚合与各意向飞手的一对一会话，含未读数与最后一条消息。
class TaskChatSessionVo {
  final int? sessionId;
  final String? taskNum;
  final int? applicationId;
  final int? riderId;
  final String? riderName;
  final int? otherUserId;
  final String? otherUserName;
  final int? ownerId;
  final String? name;
  final int? type;
  final int unreadCount;
  final String? lastMessage;
  final int? lastMessageTime;
  final int? createTime;

  const TaskChatSessionVo({
    this.sessionId,
    this.taskNum,
    this.applicationId,
    this.riderId,
    this.riderName,
    this.otherUserId,
    this.otherUserName,
    this.ownerId,
    this.name,
    this.type,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageTime,
    this.createTime,
  });

  /// 字段直取契约类（ApiTaskChatSessionVO）：契约重命名/删除字段时此处编译失败。
  factory TaskChatSessionVo.fromApi(ApiTaskChatSessionVO c) {
    return TaskChatSessionVo(
      sessionId: c.sessionId,
      taskNum: c.taskNum,
      applicationId: c.applicationId,
      riderId: c.riderId,
      riderName: c.riderName,
      otherUserId: c.otherUserId,
      otherUserName: c.otherUserName,
      ownerId: c.ownerId,
      name: c.name,
      type: c.type,
      unreadCount: c.unreadCount ?? 0,
      lastMessage: c.lastMessage,
      lastMessageTime: c.lastMessageTime,
      createTime: c.createTime,
    );
  }

  factory TaskChatSessionVo.fromJson(Map<String, dynamic> json) =>
      TaskChatSessionVo.fromApi(ApiTaskChatSessionVO.fromJson(json));

  /// 会话对方展示名（服务端优先给 otherUserName，riderName 兜底）。
  String get displayName {
    if (otherUserName != null && otherUserName!.isNotEmpty) {
      return otherUserName!;
    }
    if (riderName != null && riderName!.isNotEmpty) return riderName!;
    if (name != null && name!.isNotEmpty) return name!;
    return '飞手';
  }
}
