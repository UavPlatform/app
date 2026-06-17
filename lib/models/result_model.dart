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
    return Result(
      success: json['success'] as bool,
      code: json['code'] as int?,
      errorCode: json['errorCode'] as String?,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
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
