class FeedMediaVo {
  final int id;
  final String url;
  final String type;

  FeedMediaVo({required this.id, required this.url, required this.type});

  factory FeedMediaVo.fromJson(Map<String, dynamic> json) {
    return FeedMediaVo(
      id: json['id'] as int,
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? 'IMAGE',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'type': type};
}

class FeedVo {
  final int id;
  final int userId;
  final String userName;
  final String userType;
  final String content;
  final List<FeedMediaVo> media;
  final int likeCount;
  final int commentCount;
  final bool liked;
  final String? createTime;
  final String? updateTime;

  bool get isRider => userType == 'RIDER';

  FeedVo({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.content,
    required this.media,
    this.likeCount = 0,
    this.commentCount = 0,
    this.liked = false,
    this.createTime,
    this.updateTime,
  });

  factory FeedVo.fromJson(Map<String, dynamic> json) {
    return FeedVo(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      userType: json['userType'] as String? ?? 'USER',
      content: json['content'] as String? ?? '',
      media: (json['media'] as List<dynamic>?)?.map((e) => FeedMediaVo.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      liked: json['liked'] as bool? ?? false,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  String get timeAgo {
    if (createTime == null) return '';
    try {
      final dt = DateTime.parse(createTime!);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}天前';
      if (diff.inHours > 0) return '${diff.inHours}小时前';
      if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
      return '刚刚';
    } catch (_) {
      return '';
    }
  }
}

class FeedPageVo {
  final List<FeedVo> feeds;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  FeedPageVo({this.feeds = const [], this.currentPage = 0, this.totalPages = 0, this.totalElements = 0});

  factory FeedPageVo.fromJson(Map<String, dynamic> json) {
    return FeedPageVo(
      feeds: (json['feeds'] as List<dynamic>?)?.map((e) => FeedVo.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
    );
  }
}

class FeedCommentVo {
  final int id;
  final int userId;
  final String userName;
  final String content;
  final int? parentId;
  final String? createTime;

  FeedCommentVo({required this.id, required this.userId, required this.userName, required this.content, this.parentId, this.createTime});

  factory FeedCommentVo.fromJson(Map<String, dynamic> json) {
    return FeedCommentVo(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      parentId: json['parentId'] as int?,
      createTime: json['createTime'] as String?,
    );
  }

  String get timeAgo {
    if (createTime == null) return '';
    try {
      final dt = DateTime.parse(createTime!);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}天前';
      if (diff.inHours > 0) return '${diff.inHours}小时前';
      if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
      return '刚刚';
    } catch (_) {
      return '';
    }
  }
}

class FeedCommentPageVo {
  final List<FeedCommentVo> comments;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  FeedCommentPageVo({this.comments = const [], this.currentPage = 0, this.totalPages = 0, this.totalElements = 0});

  factory FeedCommentPageVo.fromJson(Map<String, dynamic> json) {
    return FeedCommentPageVo(
      comments: (json['comments'] as List<dynamic>?)?.map((e) => FeedCommentVo.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
    );
  }
}
