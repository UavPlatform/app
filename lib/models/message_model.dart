enum MessageType {
  system,
  chat,
}

class Message {
  final String id;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;
  final String? orderId;

  Message({
    required this.id,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.orderId,
  });
}
