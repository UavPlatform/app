import '../api/generated/openapi_models.dart';

class Result<T> {
  final bool success;
  final int? code;
  final String? errorCode;
  final String? message;
  final T? data;

  Result({
    required this.success,
    this.code,
    this.errorCode,
    this.message,
    this.data,
  });

  factory Result.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    // 信封标量字段以契约为源（ApiResult）；生成类的 fromJson 会把 data 强制转成
    // Map，无法承载本端的分页/列表载荷，故置空 data 后只取信封字段，
    // 业务数据仍由调用方按原有动态签名解码，行为不变。
    final envelope = ApiResult<dynamic>.fromJson(
      Map<String, dynamic>.from(json)..['data'] = null,
      (data) => data,
    );
    final data = json['data'];
    return Result(
      success: envelope.success as bool,
      code: envelope.code,
      errorCode: envelope.errorCode,
      message: envelope.message,
      data: data != null && fromJsonT != null ? fromJsonT(data) : null,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T? data)? toJsonT) {
    return {
      'success': success,
      'code': code,
      'errorCode': errorCode,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data) : null,
    };
  }
}
