class PilotFeed {
  final String id;
  final String pilotId;
  final String pilotName;
  final String content;
  final List<String> images; // placeholder color hashes for now
  final int likeCount;
  final bool isLiked;
  final int commentCount;
  final DateTime createdAt;

  PilotFeed({
    required this.id,
    required this.pilotId,
    required this.pilotName,
    required this.content,
    required this.images,
    required this.likeCount,
    this.isLiked = false,
    this.commentCount = 0,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}
