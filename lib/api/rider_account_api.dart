import 'http_client.dart';
import 'generated/openapi_paths.dart';
import '../models/result_model.dart';
import '../models/login_response.dart';
import '../models/rider_uav.dart';

class RiderAccountApi {
  final HttpClient _client;

  RiderAccountApi(this._client);

  /// 飞手注册
  Future<Result<LoginResponse>> register({
    required String userName,
    required String password,
    String? djiId,
  }) async {
    final body = <String, dynamic>{
      'userName': userName,
      'password': password,
    };
    if (djiId != null && djiId.isNotEmpty) {
      body['djiId'] = djiId;
    }
    final response = await _client.dio.post(ApiPaths.riderRegister, data: body);
    return LoginResponse.parseResult(response.data);
  }

  /// 绑定无人机（契约要求同时提交机型 ID，机型取自 GET /api/aircraft-models）
  Future<Result<void>> bindDrone(String djiId, {required int aircraftModelId}) async {
    final response = await _client.dio.post(
      ApiPaths.riderDroneBind,
      queryParameters: ApiPaths.riderDroneBindQuery(
        djiId: djiId,
        aircraftModelId: aircraftModelId,
      ),
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  /// 解绑无人机
  Future<Result<void>> unbindDrone(String djiId) async {
    final response = await _client.dio.delete(
      ApiPaths.riderDroneUnbind,
      queryParameters: ApiPaths.riderDroneUnbindQuery(djiId: djiId),
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  /// 我的无人机列表
  Future<Result<List<RiderUav>>> listDrones() async {
    final response = await _client.dio.get(ApiPaths.riderDroneList);
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => RiderUav.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }
}
