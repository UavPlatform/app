import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/models/result_model.dart';
import 'package:uav_pilot_app/utils/failure_message.dart';

void main() {
  const fallback = '消息发送未完成，请稍后重试';
  DioException network(DioExceptionType type, {String method = 'GET'}) =>
      DioException(
        type: type,
        requestOptions: RequestOptions(path: '/chat', method: method),
      );
  test(
    'Transport failures distinguish connecting, waiting, cancellation and certificates',
    () {
      expect(
        failureMessage(
          network(DioExceptionType.connectionTimeout),
          fallback: fallback,
        ),
        contains('连接服务器超时'),
      );
      expect(
        failureMessage(
          network(DioExceptionType.receiveTimeout),
          fallback: fallback,
        ),
        contains('服务器响应超时'),
      );
      expect(
        failureMessage(
          network(DioExceptionType.connectionError),
          fallback: fallback,
        ),
        contains('无法连接服务器'),
      );
      expect(
        failureMessage(
          network(DioExceptionType.badCertificate),
          fallback: fallback,
        ),
        contains('安全证书'),
      );
      expect(
        failureMessage(network(DioExceptionType.cancel), fallback: fallback),
        '请求已取消',
      );
    },
  );
  for (final type in [
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('Uncertain writes require checking records for $type', () {
      final message = failureMessage(
        network(type, method: 'POST'),
        fallback: fallback,
      );
      expect(message, contains('操作结果尚未确认'));
      expect(message, contains('刷新相关记录'));
    });
  }
  for (final (status, hint) in [
    (400, '填写的信息'),
    (401, '重新登录'),
    (403, '权限'),
    (404, '不存在'),
    (409, '状态已发生变化'),
    (413, '文件大小'),
    (429, '频繁'),
    (500, '服务暂时异常'),
    (503, '服务暂时不可用'),
  ]) {
    test('HTTP $status uses an actionable fallback', () {
      final request = RequestOptions(path: '/orders');
      final error = DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: request,
          statusCode: status,
          data: '<html>proxy failure</html>',
        ),
      );
      final message = failureMessage(error, fallback: fallback);
      expect(message, contains(hint));
      expect(message, isNot(contains('<html>')));
    });
  }
  test(
    'Specific backend validation survives HTTP errors and 200 business failures',
    () {
      final request = RequestOptions(path: '/chat');
      const body = {
        'success': false,
        'code': 403,
        'errorCode': 'NO_PERMISSION',
        'message': '订单已结单，只能查看聊天记录',
      };
      expect(
        failureMessage(
          DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: 403,
              data: body,
            ),
          ),
          fallback: fallback,
        ),
        body['message'],
      );
      expect(
        resultFailureMessage(
          Result<void>(
            success: false,
            code: 200,
            errorCode: 'NO_PERMISSION',
            message: body['message'] as String,
          ),
          fallback: fallback,
        ),
        body['message'],
      );
    },
  );
  test(
    'Business codes distinguish stale assessments, order changes and offline devices',
    () {
      for (final (code, hint) in [
        ('ASSESSMENT_INVALID', '重新评估'),
        ('DISPATCH_ASSIGNMENT_CHANGED', '刷新订单'),
        ('WAYBILL_DRAFT_CONFLICT', '最新草稿'),
        ('UAV_NOT_CONNECTED', '设备连接'),
        ('FILE_TOO_LARGE', '文件大小'),
        ('AMOUNT_MISMATCH', '刷新账单'),
      ]) {
        expect(
          resultFailureMessage(
            Result<void>(success: false, errorCode: code, message: '操作失败'),
            fallback: fallback,
          ),
          contains(hint),
        );
      }
    },
  );
  test(
    'Empty, diagnostic and unknown responses use context without leaking raw errors',
    () {
      for (final message in [
        '',
        '   ',
        '操作成功',
        'Internal Server Error',
        'DioException: https://private/path',
        '<h1>failure</h1>',
      ]) {
        expect(
          businessFailureMessage(message: message, fallback: fallback),
          fallback,
        );
      }
      expect(
        failureMessage(StateError('private diagnostics'), fallback: fallback),
        fallback,
      );
      expect(
        failureMessage(
          const FormatException('private JSON'),
          fallback: fallback,
        ),
        contains('数据格式异常'),
      );
      expect(
        failureMessage(const FailureNotice('订单状态已变化'), fallback: fallback),
        '订单状态已变化',
      );
    },
  );
  test('Login rejection differs from an expired authenticated session', () {
    expect(
      businessFailureMessage(statusCode: 401, fallback: fallback, login: true),
      contains('账号或密码'),
    );
    expect(
      businessFailureMessage(statusCode: 401, fallback: fallback),
      contains('登录已失效'),
    );
  });
  test(
    'Camera and gallery permission failures name the required permission',
    () {
      expect(
        failureMessage(
          PlatformException(code: 'camera_access_denied'),
          fallback: fallback,
        ),
        contains('相机权限'),
      );
      expect(
        failureMessage(
          PlatformException(code: 'photo_access_denied'),
          fallback: fallback,
        ),
        contains('照片访问权限'),
      );
    },
  );
}
