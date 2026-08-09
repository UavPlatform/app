import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../models/upload_vo.dart';
import '../../providers/upload_provider.dart';

class UploadTestPage extends ConsumerStatefulWidget {
  const UploadTestPage({super.key});

  @override
  ConsumerState<UploadTestPage> createState() => _UploadTestPageState();
}

class _UploadTestPageState extends ConsumerState<UploadTestPage> {
  final _picker = ImagePicker();
  XFile? _picked;

  Future<void> _pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _picked = f);
  }

  Future<void> _pickVideo() async {
    final f = await _picker.pickVideo(source: ImageSource.gallery);
    if (f != null) setState(() => _picked = f);
  }

  Future<void> _doUpload() async {
    if (_picked == null) return;
    final f = _picked!;
    final bytes = await f.readAsBytes();
    final ok = await ref.read(uploadProvider.notifier).upload(
          fileName: f.name,
          bytes: bytes,
          mimeType: f.mimeType,
        );
    if (ok && mounted) {
      setState(() => _picked = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上传成功'), backgroundColor: AppColors.success),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上传失败'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uploadProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('文件上传测试'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(uploadProvider.notifier).loadFiles(),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 上传区域 ---
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              // 选择文件按钮
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.uploading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('选择图片'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgInput,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.uploading ? null : _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('选择视频'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgInput,
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                ),
              ]),
              if (_picked != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 48, height: 48,
                      child: Image.file(
                        File(_picked!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_picked!.name.split('/').last,
                      style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.uploading ? null : _doUpload,
                    icon: state.uploading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload),
                    label: Text(state.uploading ? '上传中...' : '上传文件'),
                  ),
                ),
              ],
            ]),
          ),

          // --- 错误提示 ---
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),

          // --- 文件列表标题 ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              const Text('已上传文件', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${state.files.length} 个',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ]),
          ),

          // --- 文件列表 ---
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.files.isEmpty
                    ? const Center(
                        child: Text('暂无文件', style: TextStyle(color: AppColors.textHint)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: state.files.length,
                        itemBuilder: (_, i) => _buildFileRow(state.files[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(UploadVo file) {
    final sizeStr = file.fileSize > 1024 * 1024
        ? '${(file.fileSize / 1024 / 1024).toStringAsFixed(1)} MB'
        : '${(file.fileSize / 1024).toStringAsFixed(0)} KB';
    final isVideo = file.mimeType?.startsWith('video') == true;
    final isImage = file.mimeType?.startsWith('image') == true;
    final hasPreview = file.fileUrl.isNotEmpty && file.uploadStatus == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        // 缩略图
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 56,
            height: 56,
            child: hasPreview && isImage
                ? Image.network(file.fileUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(isVideo))
                : _buildPlaceholder(isVideo),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(file.originalName,
                style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Text(sizeStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              const SizedBox(width: 8),
              _buildStatusTag(file.uploadStatus),
            ]),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
          onPressed: () => _confirmDelete(file),
        ),
      ]),
    );
  }

  Widget _buildPlaceholder(bool isVideo) {
    return Container(
      color: AppColors.bgInput,
      child: Icon(
        isVideo ? Icons.videocam : Icons.image,
        size: 28,
        color: AppColors.textHint,
      ),
    );
  }

  Future<void> _confirmDelete(UploadVo file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除 ${file.originalName}？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(uploadProvider.notifier).deleteFile(file.id);
    }
  }

  Widget _buildStatusTag(String status) {
    final isDone = status == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isDone ? AppColors.statusInProgress : AppColors.statusPending,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isDone ? '完成' : status,
        style: TextStyle(
          fontSize: 10,
          color: isDone ? AppColors.statusInProgressText : AppColors.statusPendingText,
        ),
      ),
    );
  }
}
