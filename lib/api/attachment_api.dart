// 交付物附件 API（t44：t43 presigned PUT 直传 MinIO 契约）。
// - GET  /tasks/{taskNum}/attachments：附件列表（逐条含 downloadUrl，15 分钟有效）；
// - POST /tasks/{taskNum}/attachments/upload-url?fileName&contentType&sizeBytes：
//   预签名上传凭证（objectKey/uploadUrl/method/expireSeconds）；
// - 客户端直传：PUT uploadUrl（绝对地址，绕过 baseUrl）。
// 类型/大小限制（t43）：图片 jpeg/png/webp ≤20MB；视频 mp4/quicktime ≤500MB。

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/result_model.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

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
  static String? validate({required String contentType, required int sizeBytes}) {
    final isImage = allowedImageTypes.contains(contentType);
    final isVideo = allowedVideoTypes.contains(contentType);
    if (!isImage && !isVideo) {
      return '仅支持 JPG/PNG/WebP 图片或 MP4/MOV 视频';
    }
    final limit = isImage ? maxImageBytes : maxVideoBytes;
    if (sizeBytes > limit) {
      return isImage
          ? '图片超过大小限制（≤20MB）'
          : '视频超过大小限制（≤500MB）';
    }
    return null;
  }
}

/// 附件视图对象（后端附件列表条目，含临时下载地址）。
class AttachmentVo {
  final String objectKey;
  final String? fileName;
  final String? contentType;
  final int? sizeBytes;
  final String? downloadUrl;

  const AttachmentVo({
    required this.objectKey,
    this.fileName,
    this.contentType,
    this.sizeBytes,
    this.downloadUrl,
  });

  factory AttachmentVo.fromJson(Map<String, dynamic> json) {
    return AttachmentVo(
      objectKey: json['objectKey'] as String? ?? json['object_key'] as String? ?? '',
      fileName: (json['fileName'] ?? json['file_name']) as String?,
      contentType: (json['contentType'] ?? json['content_type']) as String?,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ??
          (json['size_bytes'] as num?)?.toInt(),
      downloadUrl: (json['downloadUrl'] ?? json['download_url']) as String?,
    );
  }

  bool get isImage =>
      (contentType?.startsWith('image/') ?? false) ||
      _hasImageExtension;

  bool get _hasImageExtension {
    final name = fileName?.toLowerCase() ?? '';
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  String get sizeLabel {
    final size = sizeBytes ?? 0;
    if (size <= 0) return '-';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 预签名上传凭证（后端返回，客户端直传 MinIO）。
class UploadTicket {
  final String objectKey;
  final String uploadUrl;
  final String method;
  final int expireSeconds;

  const UploadTicket({
    required this.objectKey,
    required this.uploadUrl,
    required this.method,
    required this.expireSeconds,
  });

  factory UploadTicket.fromJson(Map<String, dynamic> json) {
    return UploadTicket(
      objectKey: json['objectKey'] as String? ?? '',
      uploadUrl: json['uploadUrl'] as String? ?? '',
      method: json['method'] as String? ?? 'PUT',
      expireSeconds: (json['expireSeconds'] as num?)?.toInt() ?? 900,
    );
  }
}

class AttachmentApi {
  final HttpClient _client;

  AttachmentApi(this._client);

  /// 附件列表（任务所有者/接单飞手可见）。
  Future<Result<List<AttachmentVo>>> listAttachments(String taskNum) async {
    try {
      final response = await _client.dio.get(ApiPaths.tasksAttachmentsPath(taskNum));
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final list = data['data'];
        final attachments = <AttachmentVo>[];
        if (list is List) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              attachments.add(AttachmentVo.fromJson(item));
            }
          }
        }
        return Result(success: true, code: 200, data: attachments);
      }
      return Result(
        success: false,
        message: data is Map<String, dynamic>
            ? data['message'] as String?
            : '加载失败',
      );
    } on DioException catch (e) {
      final respData = e.response?.data;
      return Result(
        success: false,
        message: respData is Map<String, dynamic>
            ? respData['message'] as String? ?? '加载失败'
            : '加载失败，请检查网络',
      );
    }
  }

  /// 请求预签名上传凭证。
  Future<Result<UploadTicket>> requestUploadUrl({
    required String taskNum,
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.tasksAttachmentsUploadUrlPath(taskNum),
        queryParameters: ApiPaths.tasksAttachmentsUploadUrlQuery(
          contentType: contentType,
          fileName: fileName,
          sizeBytes: sizeBytes,
        ),
      );
      return Result.fromJson(
        response.data as Map<String, dynamic>,
        (data) => UploadTicket.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final respData = e.response?.data;
      if (respData is Map<String, dynamic>) {
        return Result(
          success: respData['success'] == true,
          code: respData['code'] as int?,
          errorCode: respData['errorCode'] as String?,
          message: respData['message'] as String? ?? '获取上传凭证失败',
        );
      }
      return Result(success: false, message: '获取上传凭证失败，请检查网络');
    }
  }

  /// 直传 MinIO（presigned PUT，绝对地址；测试经注入适配器拦截）。
  Future<void> uploadToStorage({
    required String uploadUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.dio.put(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': contentType},
      ),
    );
  }
}
