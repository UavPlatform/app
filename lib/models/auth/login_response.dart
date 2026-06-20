import '../result_model.dart';

class LoginResponse {
  final String token;
  final String refreshToken;

  LoginResponse({
    required this.token,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  static Result<LoginResponse> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => LoginResponse.fromJson(data));
  }
}
