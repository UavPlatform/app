import 'result_model.dart';

class RegisterResponse {
  final int id;
  final String userName;

  RegisterResponse({required this.id, required this.userName});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as int,
      userName: json['userName'] as String,
    );
  }

  static Result<RegisterResponse> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => RegisterResponse.fromJson(data));
  }
}
