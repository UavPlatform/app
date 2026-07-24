import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'http_client.dart';
import '../models/result_model.dart';
import '../models/upload_vo.dart';

class UploadApi {
  final HttpClient _client;

  UploadApi(this._client);

  // POST /upload/sign
  Future<Result<UploadSignVo>> sign({
    required String fileName,
    required int fileSize,
    String? mimeType,
    String? orderNum,
  }) async {
    final response = await _client.dio.post('/upload/sign', data: {
      'fileName': fileName,
      'fileSize': fileSize,
      if (mimeType != null) 'mimeType': mimeType,
      if (orderNum != null) 'orderNum': orderNum,
    });
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200 && data['data'] != null) {
      return Result(
        success: true,
        code: data['code'],
        message: data['message'] as String?,
        data: UploadSignVo.fromJson(data['data']),
      );
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  // PUT to pre-signed URL (raw OSS upload, no auth)
  Future<bool> uploadToOss(String preSignedUrl, List<int> bytes, String contentType) async {
    try {
      await Dio().put(
        preSignedUrl,
        data: Uint8List.fromList(bytes),
        options: Options(
          headers: {'Content-Type': contentType},
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );
      return true;
    } on DioException catch (e) {
      print('OSS PUT failed: ${e.response?.statusCode} ${e.message}');
      return false;
    }
  }

  // POST /upload/confirm/{fileId}
  Future<Result<UploadVo>> confirm(int fileId) async {
    final response = await _client.dio.post('/upload/confirm/$fileId');
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200 && data['data'] != null) {
      return Result(
        success: true,
        code: data['code'],
        message: data['message'] as String?,
        data: UploadVo.fromJson(data['data']),
      );
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  // GET /upload/list
  Future<Result<UploadPageVo>> list({int page = 0, int size = 20, String? orderNum}) async {
    final response = await _client.dio.get('/upload/list', queryParameters: {
      'page': page,
      'size': size,
      if (orderNum != null) 'orderNum': orderNum,
    });
    final data = response.data as Map<String, dynamic>;
    if (data['code'] == 200 && data['data'] != null) {
      return Result(
        success: true,
        code: data['code'],
        message: data['message'] as String?,
        data: UploadPageVo.fromJson(data['data']),
      );
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  // DELETE /upload/{id}
  Future<Result<void>> delete(int id) async {
    final response = await _client.dio.delete('/upload/$id');
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['code'] == 200,
      code: data['code'],
      message: data['message'] as String?,
    );
  }
}
