import 'http_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../models/result_model.dart';

class AuthApi {
  final HttpClient _client;

  AuthApi(this._client);

  Future<Result<LoginResponse>> login(LoginRequest request) async {
    final response = await _client.dio.post(
      '/user/login',
      data: request.toJson(),
    );
    return LoginResponse.parseResult(response.data);
  }

  Future<Result<RegisterResponse>> register(RegisterRequest request) async {
    final response = await _client.dio.post(
      '/user/register',
      data: request.toJson(),
    );
    return RegisterResponse.parseResult(response.data);
  }
}
