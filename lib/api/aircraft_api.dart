import 'http_client.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import '../models/result_model.dart';

/// 平台机型目录（GET /api/aircraft-models，仅启用机型）。
///
/// 绑定无人机（POST /rider/drone/bind）与吊运应征（POST /rider/apply）都必须
/// 从该目录选择 `aircraftModelId`——客户端不接受自填机型或金额。
class AircraftApi {
  final HttpClient _client;

  AircraftApi(this._client);

  Future<Result<List<ApiAircraftModelVO>>> listModels() async {
    final response = await _client.dio.get(ApiPaths.apiAircraftModels);
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => ApiAircraftModelVO.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(
      success: false,
      code: data['code'] as int?,
      errorCode: data['errorCode'] as String?,
      message: data['message'] as String?,
    );
  }
}
