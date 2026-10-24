import 'package:dio/dio.dart';
import '../services/attachment_file_source.dart';
import 'attachment_api.dart' show AttachmentUploadRules;
import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class DispatchMaterial {
  DispatchMaterial(this.data) {
    if (data.materialId == null ||
        data.materialId!.isEmpty ||
        data.uploadStatus != 'UPLOADED' ||
        data.downloadUrl == null ||
        data.downloadUrl!.isEmpty ||
        (data.sizeBytes ?? 0) <= 0) {
      throw const DispatchApiException('材料未得到服务端核验，请重新读取');
    }
  }
  final ApiDispatchMaterialVO data;
  String get id => data.materialId!;
}

class DispatchMaterialApi {
  DispatchMaterialApi(this.client, {Dio? storage})
    : _storage =
          storage ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(minutes: 5),
              receiveTimeout: const Duration(seconds: 60),
              followRedirects: false,
            ),
          );
  final HttpClient client;
  final Dio _storage;
  void dispose() => _storage.close(force: true);
  Future<List<DispatchMaterial>> list(String orderId) async {
    final data =
        await dispatchRequest(
              () =>
                  client.dio.get(ApiPaths.dispatchOrdersMaterialsPath(orderId)),
            )
            as List;
    return data
        .map(
          (item) => DispatchMaterial(
            ApiDispatchMaterialVO.fromJson(item as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Future<DispatchMaterial> upload(
    String orderId,
    String purpose,
    UploadCandidate file,
  ) async {
    final violation = AttachmentUploadRules.validate(
      contentType: file.contentType,
      sizeBytes: file.bytes.length,
    );
    if (violation != null || file.bytes.isEmpty) {
      throw DispatchApiException(violation ?? '文件为空');
    }
    final input = ApiDispatchMaterialUploadDTO(
      purpose: purpose,
      fileName: file.fileName,
      contentType: file.contentType,
      sizeBytes: file.bytes.length,
    );
    final raw = await dispatchRequest(
      () => client.dio.post(
        ApiPaths.dispatchOrdersMaterialsUploadTicketPath(orderId),
        data: input.toJson(),
      ),
    );
    final ticket = ApiDispatchUploadTicketVO.fromJson(
      raw as Map<String, dynamic>,
    );
    final uri = Uri.tryParse(ticket.uploadUrl ?? '');
    if (ticket.materialId == null ||
        ticket.method != 'PUT' ||
        ticket.contentType != file.contentType ||
        ticket.sizeBytes != file.bytes.length ||
        uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const DispatchApiException('上传票据不完整，请重新申请');
    }
    try {
      // A separate client has no business auth or interceptors. Do not follow signed-URL redirects.
      await _storage.put<dynamic>(
        uri.toString(),
        data: file.bytes,
        options: Options(
          headers: {
            'Content-Type': ticket.contentType,
            'Content-Length': file.bytes.length,
          },
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
    } on DioException {
      throw const DispatchApiException('文件直传未完成，请重新上传');
    }
    final confirmed = await dispatchRequest(
      () => client.dio.post(
        ApiPaths.dispatchOrdersMaterialsConfirmPath(
          ticket.materialId!,
          orderId,
        ),
      ),
    );
    return DispatchMaterial(
      ApiDispatchMaterialVO.fromJson(confirmed as Map<String, dynamic>),
    );
  }
}
