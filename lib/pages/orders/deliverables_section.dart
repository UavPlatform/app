// 交付成果区块（t44）：真实附件列表（t43 契约）+ 补充上传（presigned PUT 直传）。
// 图片缩略展示、点击预览/复制下载链接（15 分钟 presigned GET 有效）；
// 上传类型/大小限制按 t43（图片 ≤20MB、视频 ≤500MB），失败可重试。

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/attachment_api.dart';
import '../../services/attachment_file_source.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/app_colors.dart';

/// 文件来源抽象：生产默认走 image_picker 真实选择器（t48），
/// 测试注入假来源驱动完整上传流。
typedef AttachmentPicker = Future<UploadCandidate?> Function();

class DeliverablesSection extends ConsumerStatefulWidget {
  final String taskNum;

  /// 文件选择来源（未注入时点击上传会提示能力即将开放）
  final AttachmentPicker? picker;

  const DeliverablesSection({
    super.key,
    required this.taskNum,
    this.picker,
  });

  @override
  ConsumerState<DeliverablesSection> createState() =>
      _DeliverablesSectionState();
}

class _DeliverablesSectionState extends ConsumerState<DeliverablesSection> {
  List<AttachmentVo> _attachments = [];
  bool _loading = true;
  String? _error;
  bool _uploading = false;
  String? _uploadStatus;

  AttachmentApi get _attachmentApi =>
      AttachmentApi(ref.read(httpClientProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _attachmentApi.listAttachments(widget.taskNum);
      if (!mounted) return;
      if (result.success && result.data != null) {
        // 履约证据条数供「确认完成」按钮显隐消费（ADR-0003 完成闭环）。
        ref.read(taskEvidenceCountProvider(widget.taskNum).notifier).state =
            result.data!.length;
        setState(() {
          _attachments = result.data!;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result.message ?? '加载失败';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请检查网络';
        _loading = false;
      });
    }
  }

  Future<void> _startUpload() async {
    UploadCandidate? candidate;
    try {
      if (widget.picker != null) {
        // 测试/自定义来源注入
        candidate = await widget.picker!();
      } else {
        // 生产：image_picker 真实选择器（t48）
        candidate = await _pickWithSourceSheet();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未能获取文件，请检查相机/相册权限后重试')),
      );
      return;
    }
    if (!mounted || candidate == null) return;
    await _upload(candidate);
  }

  /// 来源选择底部弹窗：拍照 / 相册图片 / 相册视频（t48）
  Future<UploadCandidate?> _pickWithSourceSheet() async {
    final source = ImagePickerAttachmentSource();
    return showModalBottomSheet<UploadCandidate>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照上传'),
              onTap: () async {
                try {
                  final candidate = await source.pickFromCamera();
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, candidate);
                  }
                } catch (_) {
                  // 权限拒绝/获取失败：提示用户（t48 验收③）
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('未能获取文件，请检查相机/相册权限后重试'),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择图片'),
              onTap: () async {
                try {
                  final candidate = await source.pickFromGallery();
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, candidate);
                  }
                } catch (_) {
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('未能获取文件，请检查相机/相册权限后重试'),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('从相册选择视频'),
              onTap: () async {
                try {
                  final candidate = await source.pickGalleryVideo();
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, candidate);
                  }
                } catch (_) {
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('未能获取文件，请检查相机/相册权限后重试'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload(UploadCandidate candidate) async {
    setState(() {
      _uploading = true;
      _uploadStatus = '正在获取上传凭证…';
    });
    try {
      // 1) 类型/大小本地校验（t43 限制）
      final violation = AttachmentUploadRules.validate(
        contentType: candidate.contentType,
        sizeBytes: candidate.bytes.length,
      );
      if (violation != null) {
        if (!mounted) return;
        setState(() {
          _uploading = false;
          _uploadStatus = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(violation)));
        return;
      }

      // 2) 预签名凭证
      final ticketResult = await _attachmentApi.requestUploadUrl(
        taskNum: widget.taskNum,
        fileName: candidate.fileName,
        contentType: candidate.contentType,
        sizeBytes: candidate.bytes.length,
      );
      if (!mounted) return;
      if (!ticketResult.success || ticketResult.data == null) {
        setState(() {
          _uploading = false;
          _uploadStatus = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ticketResult.message ?? '获取上传凭证失败'),
            action: SnackBarAction(
              label: '重试',
              onPressed: () => _upload(candidate),
            ),
          ),
        );
        return;
      }
      final ticket = ticketResult.data!;

      // 3) 直传 MinIO（presigned PUT）
      setState(() => _uploadStatus = '正在上传文件…');
      await _attachmentApi.uploadToStorage(
        uploadUrl: ticket.uploadUrl,
        bytes: candidate.bytes,
        contentType: candidate.contentType,
      );
      if (!mounted) return;

      // 4) 刷新列表
      setState(() {
        _uploading = false;
        _uploadStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上传成功')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('上传失败，请检查网络后重试'),
          action: SnackBarAction(
            label: '重试',
            onPressed: () => _upload(candidate),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSection('交付成果', _buildContent());
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _load, child: const Text('重试')),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_uploading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  _uploadStatus ?? '正在上传…',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        if (_attachments.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '暂无交付成果',
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
          )
        else
          ..._attachments.map(_buildAttachmentTile),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploading ? null : _startUpload,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('补充上传照片/视频',
                style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentTile(AttachmentVo attachment) {
    final preview = attachment.downloadUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showAttachmentDialog(attachment),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: attachment.isImage && preview != null
                    ? Image.network(
                        preview,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_outlined,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName ?? attachment.objectKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attachment.sizeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentDialog(AttachmentVo attachment) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(attachment.fileName ?? attachment.objectKey),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachment.isImage && attachment.downloadUrl != null)
              Flexible(
                child: Image.network(
                  attachment.downloadUrl!,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 80,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              Text(
                '该附件类型不支持在线预览，可复制下载链接获取文件。',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
              ),
            const SizedBox(height: 12),
            Text(
              '大小：${attachment.sizeLabel}',
              style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: attachment.downloadUrl ?? ''),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('下载链接已复制（15 分钟内有效）')),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('复制下载链接'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
