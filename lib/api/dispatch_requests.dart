import '../utils/failure_message.dart';
import 'package:dio/dio.dart';
import 'dispatch_api.dart';

Future<dynamic> dispatchRequest(
  Future<Response<dynamic>> Function() request, {
  bool allowEmpty = false,
}) async {
  try {
    final body = (await request()).data;
    if (body is! Map ||
        body['success'] != true ||
        (!allowEmpty && body['data'] == null)) {
      throw DispatchApiException(
        body is Map
            ? businessFailureMessage(
                message: body['message'] as String?,
                errorCode: body['errorCode'] as String?,
                statusCode: body['code'] as int?,
                fallback: '未确认操作结果，请查询订单',
              )
            : '返回结果无效，请重试',
        code: body is Map ? body['errorCode'] as String? : null,
      );
    }
    return body['data'];
  } on DioException catch (error) {
    final body = error.response?.data;
    throw DispatchApiException(
      failureMessage(error, fallback: '未确认操作结果，请查询相关记录后再操作'),
      code: body is Map ? body['errorCode'] as String? : null,
    );
  }
}
