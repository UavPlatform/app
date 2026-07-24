class UploadSignVo {
  final int fileId;
  final String preSignedUrl;
  final String objectKey;
  final String expiresAt;

  UploadSignVo({
    required this.fileId,
    required this.preSignedUrl,
    required this.objectKey,
    required this.expiresAt,
  });

  factory UploadSignVo.fromJson(Map<String, dynamic> json) {
    return UploadSignVo(
      fileId: json['fileId'] as int,
      preSignedUrl: json['preSignedUrl'] as String,
      objectKey: json['objectKey'] as String,
      expiresAt: json['expiresAt'] as String? ?? '',
    );
  }
}

class UploadVo {
  final int id;
  final String? uploadId;
  final String originalName;
  final String? storagePath;
  final String fileUrl;
  final int fileSize;
  final String? mimeType;
  final String? fileSuffix;
  final String uploadStatus;
  final String? orderNum;
  final int? userId;
  final String? createTime;

  UploadVo({
    required this.id,
    this.uploadId,
    required this.originalName,
    this.storagePath,
    required this.fileUrl,
    required this.fileSize,
    this.mimeType,
    this.fileSuffix,
    required this.uploadStatus,
    this.orderNum,
    this.userId,
    this.createTime,
  });

  factory UploadVo.fromJson(Map<String, dynamic> json) {
    return UploadVo(
      id: json['id'] as int,
      uploadId: json['uploadId'] as String?,
      originalName: json['originalName'] as String? ?? '',
      storagePath: json['storagePath'] as String?,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      mimeType: json['mimeType'] as String?,
      fileSuffix: json['fileSuffix'] as String?,
      uploadStatus: json['uploadStatus'] as String? ?? '',
      orderNum: json['orderNum'] as String?,
      userId: json['userId'] as int?,
      createTime: json['createTime'] as String?,
    );
  }
}

class UploadPageVo {
  final List<UploadVo> files;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  UploadPageVo({
    required this.files,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  factory UploadPageVo.fromJson(Map<String, dynamic> json) {
    return UploadPageVo(
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => UploadVo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
    );
  }
}
