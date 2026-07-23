import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/pilot_feed.dart';
import '../../services/mock_data_service.dart';

class FeedDetailPage extends StatefulWidget {
  final PilotFeed feed;
  const FeedDetailPage({super.key, required this.feed});

  @override
  State<FeedDetailPage> createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends State<FeedDetailPage> {
  late bool _liked;
  late int _likeCount;
  final _commentCtrl = TextEditingController();
  final _comments = <_Comment>[];

  static const _feedColors = [
    Color(0xFF5B7FA8), Color(0xFF6B8E6B), Color(0xFF8B7355), Color(0xFF7B6B8A),
    Color(0xFF4A8090), Color(0xFF8A7060), Color(0xFF607888), Color(0xFF788860),
  ];

  @override
  void initState() {
    super.initState();
    _liked = widget.feed.isLiked;
    _likeCount = widget.feed.likeCount;
    _comments.addAll(_buildMockComments());
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  List<_Comment> _buildMockComments() {
    return [
      _Comment(name: '飞翼用户', avatar: '用', text: '拍得太好了！什么设备拍的？', time: '1小时前'),
      _Comment(name: '陈师傅', avatar: '陈', text: '这角度绝了，学习了👍', time: '3小时前'),
      if (widget.feed.commentCount > 2)
        _Comment(name: '周师傅', avatar: '周', text: '湘潭这天气确实适合航拍，改天约飞', time: '5小时前'),
    ];
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
  }

  void _submitComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, _Comment(name: '我', avatar: '我', text: text, time: '刚刚'));
      _commentCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hash = widget.feed.id.hashCode.abs();
    final color = _feedColors[hash % _feedColors.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('动态详情'),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Hero image
                Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(color: color),
                  child: Center(
                    child: Icon(Icons.image, size: 80, color: Colors.white.withAlpha(70)),
                  ),
                ),
                // Author header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(widget.feed.pilotName[0],
                          style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.feed.pilotName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(widget.feed.timeAgo,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _startChat(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          minimumSize: Size.zero,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('私信', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(widget.feed.content,
                    style: const TextStyle(fontSize: 15, height: 1.6)),
                ),
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('$_likeCount 赞', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 16),
                      Text('${_comments.length} 评论',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1),
                // Action bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAction(Icons.favorite, _liked ? '已赞' : '点赞',
                        color: _liked ? AppColors.danger : null, onTap: _toggleLike),
                      _buildAction(Icons.chat_bubble_outline, '评论', onTap: () => FocusScope.of(context).requestFocus()),
                      _buildAction(Icons.share_outlined, '分享', onTap: () {}),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Comments
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('评论', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                ..._comments.map((c) => _buildCommentTile(c)),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Bottom input
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgWhite,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: '说点什么...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _liked ? AppColors.danger.withAlpha(25) : AppColors.bgInput,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite, size: 20, color: _liked ? AppColors.danger : AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: color ?? AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(_Comment comment) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            child: Text(comment.avatar, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text(comment.time, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {},
                  child: const Text('回复', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.favorite_border, size: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context) {
    final pilot = MockDataService.pilots.cast<dynamic>().firstWhere(
      (p) => p.nickname == widget.feed.pilotName,
      orElse: () => null,
    );
    if (pilot != null) {
      context.push('/chat/1?name=${Uri.encodeComponent(widget.feed.pilotName)}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('飞手暂时不在线'), duration: Duration(seconds: 2)),
      );
    }
  }
}

class _Comment {
  final String name;
  final String avatar;
  final String text;
  final String time;
  _Comment({required this.name, required this.avatar, required this.text, required this.time});
}
