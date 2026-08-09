import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/feed_vo.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';

class FeedDetailPage extends ConsumerStatefulWidget {
  final int feedId;
  const FeedDetailPage({super.key, required this.feedId});

  @override
  ConsumerState<FeedDetailPage> createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends ConsumerState<FeedDetailPage> {
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  final _imagePageCtrl = PageController();
  int _currentImageIdx = 0;

  static const _colors = [Color(0xFF5B7FA8), Color(0xFF6B8E6B), Color(0xFF8B7355), Color(0xFF7B6B8A), Color(0xFF4A8090), Color(0xFF8A7060)];

  int? get _myId { final u = ref.read(authProvider).user?.userId; return u != null ? int.tryParse(u) : null; }

  @override
  void dispose() { _commentCtrl.dispose(); _imagePageCtrl.dispose(); super.dispose(); }

  Future<void> _toggleLike() async {
    final ok = await ref.read(feedDetailProvider(widget.feedId).notifier).toggleLike();
    if (ok) { final f = ref.read(feedDetailProvider(widget.feedId)).feed; if (f != null) ref.read(feedListProvider.notifier).updateFeed(f); }
  }

  Future<void> _submit() async {
    final t = _commentCtrl.text.trim(); if (t.isEmpty) return;
    setState(() => _sending = true);
    final ok = await ref.read(feedCommentListProvider(widget.feedId).notifier).post(t);
    if (mounted) { setState(() => _sending = false); if (ok) _commentCtrl.clear(); else _toast('发送失败'); }
  }

  void _goEdit(FeedVo f) => context.push('/feed/publish', extra: f);

  Future<void> _confirmDelete(FeedVo f) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: const Text('确认删除', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 16), child: Text('删除后不可恢复', style: TextStyle(fontSize: 14, color: Color(0xFF999999)))),
          const Divider(height: 1),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => Navigator.pop(context, false), child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFF0F0F0), width: 0.5))), child: const Center(child: Text('取消', style: TextStyle(fontSize: 16, color: Color(0xFF999999))))))),
            Expanded(child: GestureDetector(onTap: () => Navigator.pop(context, true), child: Container(padding: const EdgeInsets.symmetric(vertical: 16), child: const Center(child: Text('确认', style: TextStyle(fontSize: 16, color: Color(0xFF4A148C), fontWeight: FontWeight.w600)))))),
          ]),
        ]),
      ),
    );
    if (ok == true && mounted) {
      ref.read(feedApiProvider).deleteFeed(f.id);
      ref.read(feedListProvider.notifier).removeFeed(f.id);
      context.pop();
    }
  }

  void _toast(String m) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m))); }

  void _openImageViewer(int initialIdx, List<FeedMediaVo> media) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ImageViewer(initialIdx: initialIdx, media: media)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fs = ref.watch(feedDetailProvider(widget.feedId));
    final cs = ref.watch(feedCommentListProvider(widget.feedId));
    if (fs.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final f = fs.feed;
    if (f == null) return Scaffold(appBar: AppBar(title: const Text('动态详情')), body: Center(child: Text(fs.error ?? '加载失败', style: const TextStyle(color: AppColors.textSecondary))));

    final isOwner = _myId != null && _myId == f.userId;
    final w = MediaQuery.of(context).size.width;
    final color = _colors[f.id % _colors.length];

    return Scaffold(
      appBar: AppBar(title: const Text('动态详情'), actions: [
        if (isOwner) PopupMenuButton<String>(
          onSelected: (v) { if (v == 'edit') _goEdit(f); if (v == 'delete') _confirmDelete(f); },
          itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('编辑')), PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red)))],
        ),
      ]),
      body: Column(children: [
        Expanded(child: ListView(children: [
          if (f.media.isNotEmpty) ...[
            SizedBox(
              height: w * 0.8,
              child: PageView.builder(
                controller: _imagePageCtrl,
                onPageChanged: (i) => setState(() => _currentImageIdx = i),
                itemCount: f.media.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openImageViewer(i, f.media),
                  child: Container(
                    color: color,
                    child: Image.network(f.media[i].url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image, size: 80, color: Colors.white.withAlpha(70)))),
                  ),
                ),
              ),
            ),
            if (f.media.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(f.media.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentImageIdx ? 16 : 6, height: 4,
                    decoration: BoxDecoration(color: i == _currentImageIdx ? AppColors.primary : const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
                  )),
                ),
              ),
          ] else
            Container(width: double.infinity, height: 200, decoration: BoxDecoration(color: color), child: Center(child: Icon(Icons.image, size: 80, color: Colors.white.withAlpha(70)))),
          Padding(padding: const EdgeInsets.all(16), child: GestureDetector(
            onTap: () {
              if (f.isRider) {
                context.push('/rider/${f.userId}');
              } else {
                _toast('无权访问该用户主页');
              }
            },
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.primaryLight, child: Text(f.userName.isNotEmpty ? f.userName[0] : '?', style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600))),
              const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(f.userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), Text(f.timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
            ]),
          )),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(f.content, style: const TextStyle(fontSize: 15, height: 1.6))),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [Text('${f.likeCount} 赞', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)), const SizedBox(width: 16), Text('${f.commentCount} 评论', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))])),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _btn(Icons.favorite, f.liked ? '已赞' : '点赞', color: f.liked ? AppColors.danger : null, onTap: _toggleLike),
            _btn(Icons.chat_bubble_outline, '评论'),
            _btn(Icons.share_outlined, '分享'),
          ])),
          const Divider(height: 1),
          const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('评论', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          if (cs.loading) const Center(child: CircularProgressIndicator()),
          // No "no comments" placeholder needed — just don't show anything
          ...cs.comments.map((c) => Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text(c.userName.isNotEmpty ? c.userName[0] : '?', style: const TextStyle(fontSize: 11, color: AppColors.primary))),
            const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(c.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(width: 8), Text(c.timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textHint))]), const SizedBox(height: 4), Text(c.content, style: const TextStyle(fontSize: 14)),
            ])),
          ]))),
          const SizedBox(height: 80),
        ])),
        Container(
          decoration: const BoxDecoration(color: AppColors.bgWhite, border: Border(top: BorderSide(color: AppColors.divider))),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SafeArea(top: false, child: Row(children: [
            Expanded(child: TextField(controller: _commentCtrl, decoration: InputDecoration(hintText: '说点什么...', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), filled: true, fillColor: AppColors.bgInput, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)), textInputAction: TextInputAction.send, onSubmitted: (_) => _submit())),
            const SizedBox(width: 8),
            _sending ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(onPressed: _submit, icon: const Icon(Icons.send, color: AppColors.primary)),
          ])),
        ),
      ]),
    );
  }

  Widget _btn(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20, color: color ?? AppColors.textSecondary), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 13, color: color ?? AppColors.textSecondary))])));
  }
}

class _ImageViewer extends StatefulWidget {
  final int initialIdx;
  final List<FeedMediaVo> media;
  const _ImageViewer({required this.initialIdx, required this.media});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _ctrl;
  late int _idx;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIdx;
    _ctrl = PageController(initialPage: _idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: widget.media.length > 1
            ? Text('${_idx + 1}/${widget.media.length}', style: const TextStyle(color: Colors.white, fontSize: 15))
            : null,
      ),
      body: PageView.builder(
        controller: _ctrl,
        onPageChanged: (i) => setState(() => _idx = i),
        itemCount: widget.media.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4.0,
          child: Center(
            child: Image.network(widget.media[i].url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 80)),
          ),
        ),
      ),
    );
  }
}
