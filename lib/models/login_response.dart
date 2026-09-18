import '../api/generated/openapi_models.dart';
import 'result_model.dart';

class LoginResponse {
  final String token;
  final String refreshToken;

  LoginResponse({
    required this.token,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final c = ApiUserLoginVO.fromJson(json);
    return LoginResponse(
      token: c.token as String,
      refreshToken: c.refreshToken as String,
    );
  }

  static Result<LoginResponse> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => LoginResponse.fromJson(data));
  }
}
