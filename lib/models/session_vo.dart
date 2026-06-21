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
  });

  factory SessionVo.fromJson(Map<String, dynamic> json) {
    return SessionVo(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: (json['type'] as num).toInt(),
      userIds: (json['userIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      createTime: _parseTimestamp(json['createTime']),
      otherUserName: json['otherUserName'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: _parseNullableTimestamp(json['lastMessageTime']),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
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
    );
  }

  static int _parseTimestamp(dynamic value) {
    return _parseNullableTimestamp(value) ?? 0;
  }

  static int? _parseNullableTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
