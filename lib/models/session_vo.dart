class SessionVo {
  final int id;
  final String name;
  final int type;
  final List<int> userIds;
  final String? avatar;
  final String? description;
  final String? createTime;
  final String? otherUserName;
  final String? lastMessage;

  SessionVo({
    required this.id,
    required this.name,
    required this.type,
    required this.userIds,
    this.avatar,
    this.description,
    this.createTime,
    this.otherUserName,
    this.lastMessage,
  });

  factory SessionVo.fromJson(Map<String, dynamic> json) {
    return SessionVo(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: (json['type'] as num).toInt(),
      userIds: (json['userIds'] as List<dynamic>).map((e) => (e as num).toInt()).toList(),
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      createTime: _parseCreateTime(json['createTime']),
      otherUserName: json['otherUserName'] as String?,
      lastMessage: json['lastMessage'] as String?,
    );
  }

  static String? _parseCreateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }
}
