// 附件上传限制与校验（t43 契约：图片 jpeg/png/webp ≤20MB；视频 mp4/quicktime ≤500MB）。

/// 上传限制与校验（t43 契约）。
class AttachmentUploadRules {
  static const int maxImageBytes = 20 * 1024 * 1024;
  static const int maxVideoBytes = 500 * 1024 * 1024;
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  static const List<String> allowedVideoTypes = [
    'video/mp4',
    'video/quicktime',
  ];

  /// 校验 contentType 与大小；违规返回用户可读文案，合规返回 null。
  static String? validate({
    required String contentType,
    required int sizeBytes,
  }) {
    final isImage = allowedImageTypes.contains(contentType);
    final isVideo = allowedVideoTypes.contains(contentType);
    if (!isImage && !isVideo) {
      return '仅支持 JPG/PNG/WebP 图片或 MP4/MOV 视频';
    }
    final limit = isImage ? maxImageBytes : maxVideoBytes;
    if (sizeBytes > limit) {
      return isImage ? '图片超过大小限制（≤20MB）' : '视频超过大小限制（≤500MB）';
    }
    return null;
  }
}
