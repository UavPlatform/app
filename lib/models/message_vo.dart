class MessageVo {
  final String msgId;
  final int msgType;
  final int fromUserId;
  final int? toUserId;
  final int timestamp;
  final String content;
  final bool isOffline;

  MessageVo({
    required this.msgId,
    required this.msgType,
    required this.fromUserId,
    this.toUserId,
    required this.timestamp,
    required this.content,
    this.isOffline = false,
  });

  factory MessageVo.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>?;
    return MessageVo(
      msgId: json['msgId'] as String? ?? '',
      msgType: _parseMsgType(json['msgType']),
      fromUserId: (json['fromUserId'] as num?)?.toInt() ?? 0,
      toUserId: (json['toUserId'] as num?)?.toInt(),
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      content: payload?['text'] as String? ?? '',
      isOffline: json['isOffline'] as bool? ?? false,
    );
  }

  static int _parseMsgType(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      switch (value) {
        case 'CHAT': return 0;
        case 'NOTICE': return 1;
        case 'ORDER': return 2;
        case 'COMMAND': return 3;
        default: return 0;
      }
    }
    return 0;
  }
}
