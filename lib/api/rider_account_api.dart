import 'http_client.dart';
import 'generated/openapi_paths.dart';
import '../models/result_model.dart';
import '../models/login_response.dart';

class RiderAccountApi {
  final HttpClient _client;

  RiderAccountApi(this._client);

  /// 飞手注册
  Future<Result<LoginResponse>> register({
    required String userName,
    required String password,
    String? djiId,
  }) async {
    final body = <String, dynamic>{'userName': userName, 'password': password};
    if (djiId != null && djiId.isNotEmpty) {
      body['djiId'] = djiId;
    }
    final response = await _client.dio.post(ApiPaths.riderRegister, data: body);
    return LoginResponse.parseResult(response.data);
  }
}
