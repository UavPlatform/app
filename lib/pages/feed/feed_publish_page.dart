import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/feed_vo.dart';
import '../../providers/feed_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/feed_draft_service.dart';

final _draftProvider = Provider<FeedDraftService>((ref) => FeedDraftService(ref.watch(sharedPreferencesProvider)));

class FeedPublishPage extends ConsumerStatefulWidget {
  final FeedVo? editFeed;
  const FeedPublishPage({super.key, this.editFeed});

  @override
  ConsumerState<FeedPublishPage> createState() => _FeedPublishPageState();
}

class _FeedPublishPageState extends ConsumerState<FeedPublishPage> {
  final _picker = ImagePicker();
  final _contentCtrl = TextEditingController();
  final _localFiles = <File>[];
  bool _saveDraft = true;

  bool get _isEdit => widget.editFeed != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _contentCtrl.text = widget.editFeed!.content;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(feedPublishProvider.notifier).initEdit(widget.editFeed!);
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _checkDraft();
        });
      });
    }
  }

  void _checkDraft() {
    final d = ref.read(_draftProvider).load();
    if (d.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('恢复草稿'),
      content: Text('有未发布草稿（${d.content.length}字），恢复？'),
      actions: [
        TextButton(onPressed: () { ref.read(_draftProvider).clear(); Navigator.pop(ctx); }, child: const Text('丢弃', style: TextStyle(color: Colors.grey))),
        FilledButton(onPressed: () { setState(() { _contentCtrl.text = d.content; _localFiles.clear(); for (final p in d.mediaPaths) { final f = File(p); if (f.existsSync()) _localFiles.add(f); } }); Navigator.pop(ctx); }, child: const Text('恢复')),
      ],
    ));
  }

  Future<void> _pickMedia() async {
    final st = ref.read(feedPublishProvider);
    if (st.mediaIds.length + _localFiles.length >= 9) { _toast('最多9张'); return; }
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f == null) return;
    setState(() => _localFiles.add(File(f.path)));
    final bytes = await f.readAsBytes();
    final mt = f.mimeType ?? _mime(f.name);
    final id = await ref.read(feedPublishProvider.notifier).uploadMedia(f.name, bytes, mt);
    if (mounted && id == null) {
      setState(() => _localFiles.removeWhere((x) => x.path == f.path));
      _toast('上传失败');
    }
  }

  String? _mime(String name) {
    switch (name.split('.').last.toLowerCase()) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return null;
    }
  }

  Future<void> _saveDraftFn() async {
    await ref.read(_draftProvider).save(FeedDraft(content: _contentCtrl.text.trim(), mediaPaths: _localFiles.map((f) => f.path).toList()));
    if (mounted) _toast('已保存');
  }

  Future<void> _submit() async {
    final c = _contentCtrl.text.trim();
    if (c.isEmpty || c.length > 200) { _toast('内容需1-200字符'); return; }
    final ok = await ref.read(feedPublishProvider.notifier).submit(c);
    if (!mounted) return;
    if (ok) {
      if (!_isEdit) await ref.read(_draftProvider).clear();
      ref.read(feedListProvider.notifier).refresh();
      _toast(_isEdit ? '已编辑' : '已发布');
      context.pop();
    } else {
      _toast(ref.read(feedPublishProvider).error ?? '失败');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  void dispose() { _contentCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(feedPublishProvider);
    final len = _contentCtrl.text.length;
    final total = st.mediaIds.length + _localFiles.length;
    final canSubmit = !st.busy && !st.uploading && len > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: GestureDetector(onTap: () => context.pop(), child: const Center(child: Icon(Icons.close, size: 22, color: Colors.black87))),
        title: Text(_isEdit ? '编辑动态' : '发表动态', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.black87)),
        centerTitle: true, backgroundColor: Colors.white, elevation: 0,
        actions: [if (!_isEdit) TextButton(onPressed: _saveDraftFn, child: const Text('存草稿', style: TextStyle(fontSize: 14, color: Color(0xFF576B95))))],
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 16), child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _contentCtrl, maxLength: 200, maxLines: 8, minLines: 5,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.55),
              decoration: const InputDecoration(hintText: '分享新鲜事...', hintStyle: TextStyle(fontSize: 15, color: Color(0xFFB0B0B0)), border: InputBorder.none, counterText: ''),
            ),
          ),
          if (total > 0)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Wrap(spacing: 6, runSpacing: 6, children: [
              ..._localFiles.asMap().entries.map((e) {
                final uploaded = e.key < st.mediaIds.length;
                return _thumb(
                  child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(e.value, width: 84, height: 84, fit: BoxFit.cover)),
                  done: uploaded,
                  uploading: !uploaded && st.uploading,
                  onRemove: st.uploading && !uploaded ? null : () => _confirmRemove(e.key, uploaded),
                );
              }),
              if (total < 9)
                GestureDetector(onTap: st.uploading ? null : _pickMedia, child: Container(width: 84, height: 84, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.add, size: 30, color: Color(0xFFC0C0C0)))),
            ])),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20),
          if (total == 0)
            GestureDetector(
              onTap: st.uploading ? null : _pickMedia,
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [Icon(Icons.image_outlined, size: 22, color: Color(0xFF576B95)), SizedBox(width: 12), Text('添加图片', style: TextStyle(fontSize: 15, color: Color(0xFF576B95)))])),
            ),
          const Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(children: [
            const Text('自动保存草稿', style: TextStyle(fontSize: 15, color: Colors.black87)),
            const Spacer(),
            SizedBox(height: 28, child: Switch(value: _saveDraft, onChanged: (v) => setState(() => _saveDraft = v), activeColor: const Color(0xFF07C160))),
          ])),
          const Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20),
          if (st.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(st.error!, style: const TextStyle(fontSize: 13, color: Colors.redAccent))),
        ]))),
        if (total > 0 && len == 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('单发图片不可以发表哦...', style: TextStyle(fontSize: 12, color: Color(0xFFB0B0B0))),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5))),
          child: Row(children: [
            GestureDetector(onTap: st.uploading ? null : _pickMedia, child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.image_outlined, size: 22, color: Color(0xFF576B95)), if (total > 0) ...[const SizedBox(width: 4), Text('$total', style: const TextStyle(fontSize: 13, color: Color(0xFF576B95)))]])),
            const SizedBox(width: 16), Text('$len/200', style: TextStyle(fontSize: 12, color: len > 190 ? Colors.redAccent : const Color(0xFFB0B0B0))), const Spacer(),
            ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: st.busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('发表'),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _confirmRemove(int index, bool uploaded) async {
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
      setState(() => _localFiles.removeAt(index));
      if (uploaded) ref.read(feedPublishProvider.notifier).removeMedia(index);
    }
  }

  Widget _thumb({required Widget child, bool uploading = false, bool done = false, VoidCallback? onRemove}) {
    return Stack(clipBehavior: Clip.none, children: [
      child,
      if (done) Positioned.fill(child: Container(decoration: BoxDecoration(color: const Color(0x3307C160), borderRadius: BorderRadius.circular(4)), child: const Center(child: Icon(Icons.check_circle, color: Color(0xFF07C160), size: 28)))),
      if (uploading) Positioned.fill(child: Container(decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)), child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))))),
      if (onRemove != null) Positioned(right: -5, top: -5, child: GestureDetector(onTap: onRemove, child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFF4A4A4A), shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)))),
    ]);
  }
}
