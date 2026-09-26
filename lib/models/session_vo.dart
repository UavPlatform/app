import '../api/generated/openapi_models.dart';

class SessionVo {
  final int id;
  final String name;
  final int type;
  final List<int> userIds;
  final String? avatar;
  final String? description;
  final int createTime;
  final String? otherUserName;
  final String? lastMessage;
  final int? lastMessageTime;
  final int unreadCount;

  /// 订单内会话绑定（ADR-0003）：该会话归属的任务编号与应征记录。
  final String? taskNum;
  final int? applicationId;

  SessionVo({
    required this.id,
    required this.name,
    required this.type,
    required this.userIds,
    this.avatar,
    this.description,
    this.createTime = 0,
    this.otherUserName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.taskNum,
    this.applicationId,
  });

  factory SessionVo.fromJson(Map<String, dynamic> json) {
    final c = ApiSessionVO.fromJson(json);
    return SessionVo(
      id: c.id as int,
      name: c.name as String,
      type: c.type as int,
      userIds: c.userIds as List<int>,
      avatar: c.avatar,
      description: c.description,
      createTime: c.createTime ?? 0,
      otherUserName: c.otherUserName,
      lastMessage: c.lastMessage,
      lastMessageTime: c.lastMessageTime,
      unreadCount: c.unreadCount ?? 0,
      taskNum: c.taskNum,
      applicationId: c.applicationId,
    );
  }

  int get sortTime => lastMessageTime ?? createTime;

  SessionVo copyWith({
    String? lastMessage,
    int? lastMessageTime,
    int? unreadCount,
  }) {
    return SessionVo(
      id: id,
      name: name,
      type: type,
      userIds: userIds,
      avatar: avatar,
      description: description,
      createTime: createTime,
      otherUserName: otherUserName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      taskNum: taskNum,
      applicationId: applicationId,
    );
  }
}
