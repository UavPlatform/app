// 附件文件来源（t48）：image_picker 真实选择器（拍照/相册图片/相册视频），
// 统一产出 UploadCandidate 供 t44 上传链路消费。
// 用户取消返回 null；平台异常（权限拒绝等）由调用方捕获并提示。

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// 待上传文件候选。
class UploadCandidate {
  final String fileName;
  final String contentType;
  final Uint8List bytes;

  const UploadCandidate({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });
}

/// 按扩展名推导 contentType（与 t43 允许类型对齐）。
String attachmentContentTypeFor(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.mp4')) {
    return 'video/mp4';
  }
  if (lower.endsWith('.mov')) {
    return 'video/quicktime';
  }
  return 'application/octet-stream';
}

/// image_picker 真实实现。
class ImagePickerAttachmentSource {
  final ImagePicker _picker;

  ImagePickerAttachmentSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  /// 拍照
  Future<UploadCandidate?> pickFromCamera() =>
      _pickImage(ImageSource.camera);

  /// 相册选图
  Future<UploadCandidate?> pickFromGallery() =>
      _pickImage(ImageSource.gallery);

  /// 相册选视频
  Future<UploadCandidate?> pickGalleryVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    return _toCandidate(file);
  }

  Future<UploadCandidate?> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 90);
    return _toCandidate(file);
  }

  Future<UploadCandidate?> _toCandidate(XFile? file) async {
    if (file == null) return null;
    final bytes = await File(file.path).readAsBytes();
    return UploadCandidate(
      fileName: file.name,
      contentType: attachmentContentTypeFor(file.name),
      bytes: bytes,
    );
  }
}
