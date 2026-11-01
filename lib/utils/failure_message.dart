import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../models/result_model.dart';
import '../api/generated/openapi_paths.dart';

/// REQ-ALL-XC-002：展示原因和下一步，不把所有异常归为网络问题。
abstract interface class UserFacingFailure {
  String get message;
}

class FailureNotice implements Exception, UserFacingFailure {
  const FailureNotice(this.message);
  @override
  final String message;
  @override
  String toString() => message;
}

const _businessMessages = <String, String>{
  'WAYBILL_DRAFT_CONFLICT': '账号草稿已在其他位置更新，请先恢复最新草稿再保存',
  'DISPATCH_UNAVAILABLE': '当前暂不支持下单，请查看下单条件说明',
  'ASSESSMENT_INVALID': '运单评估已失效，请重新评估后下单',
  'AIRSPACE_PROHIBITED': '所选航线涉及禁飞区域，请调整起终点后重新评估',
  'IDEMPOTENCY_CONFLICT': '本次请求对应的运单信息已变化，请先查询原订单',
  'DISPATCH_ASSIGNMENT_CHANGED': '接单状态已变化，请刷新订单后继续',
  'ORDER_ALREADY_EXISTS': '您有待支付订单，请先处理已有订单',
  'ORDER_NOT_FOUND': '订单不存在或已不可用，请返回订单列表刷新',
  'ORDER_STATUS_INVALID': '当前订单状态不支持此操作，请刷新订单查看最新进度',
  'SESSION_NOT_FOUND': '聊天会话已不可用，请返回订单重新进入聊天',
  'NO_PERMISSION': '您没有此操作的权限，请确认当前账号及订单归属',
  'RATE_LIMITED': '操作过于频繁，请稍后再试',
  'UAV_NOT_FOUND': '无人机不存在，请刷新设备列表',
  'UAV_NOT_CONNECTED': '无人机尚未连接，请检查设备连接后重试',
  'UAV_STATUS_NOT_FOUND': '无人机尚未上报状态，请等待设备上线',
  'LIVE_ACK_TIMEOUT': '设备未及时响应图传命令，请检查设备连接后刷新图传状态',
  'FILE_UPLOAD_EXPIRED': '上传凭证已过期，请重新选择文件上传',
  'FILE_TOO_LARGE': '文件大小超过限制，请压缩或选择较小文件',
  'FILE_TYPE_NOT_ALLOWED': '不支持此文件格式，请选择支持的图片或视频',
  'FILE_ACCESS_DENIED': '您没有查看此文件的权限，请确认当前账号',
  'AIRCRAFT_MODEL_REQUIRED': '请先选择无人机机型',
  'AIRCRAFT_MODEL_NOT_FOUND': '该机型不存在或已停用，请重新选择',
  'AIRCRAFT_MODEL_MISMATCH': '设备与所选机型不一致，请核对后重新选择',
  'EXCEEDS_PAYLOAD': '货物重量超过所选机型载重，请更换合适的无人机',
  'DELIVERY_EVIDENCE_REQUIRED': '请先上传交付凭证，再确认送达',
  'AMOUNT_MISMATCH': '订单金额与最新报价不一致，请刷新账单后再支付',
  'ENDPOINT_REMOVED': '当前功能版本已停用，请更新 App 后使用',
};

String resultFailureMessage(
  Result<dynamic> result, {
  required String fallback,
  bool login = false,
}) => businessFailureMessage(
  message: result.message,
  errorCode: result.errorCode,
  statusCode: result.code,
  fallback: fallback,
  login: login,
);

String businessFailureMessage({
  String? message,
  String? errorCode,
  int? statusCode,
  required String fallback,
  bool login = false,
}) {
  // Specific validation/business messages are more useful than a code default.
  final detail = message?.trim();
  if (detail != null && _isUseful(detail)) return detail;
  final known = _businessMessages[errorCode];
  if (known != null) return known;
  if (errorCode == 'INTERNAL_ERROR') return '服务暂时异常，请稍后再试';
  if (errorCode == 'INVALID_PARAM') return '填写的信息不符合要求，请检查必填项及格式';
  return switch (statusCode) {
    400 || 422 => '填写的信息不符合要求，请检查必填项及格式',
    401 => login ? '账号或密码不正确，请核对后重新输入' : '登录已失效，请重新登录后继续',
    403 => '您没有此操作的权限，请确认当前账号及订单归属',
    404 => '所需信息不存在或已不可用，请返回列表刷新',
    409 => '数据状态已发生变化，请刷新后再操作',
    413 => '文件大小超过限制，请压缩或选择较小文件',
    429 => '操作过于频繁，请稍后再试',
    502 || 503 || 504 => '服务暂时不可用，请稍后再试',
    final code? when code >= 500 => '服务暂时异常，请稍后再试',
    _ => fallback,
  };
}

String failureMessage(Object error, {required String fallback}) {
  if (error is UserFacingFailure) return error.message;
  if (error is DioException) {
    final response = error.response;
    if (response != null) {
      final body = response.data;
      return businessFailureMessage(
        message: body is Map && body['message'] is String
            ? body['message'] as String
            : null,
        errorCode: body is Map && body['errorCode'] is String
            ? body['errorCode'] as String
            : null,
        statusCode: response.statusCode,
        fallback: fallback,
        login: error.requestOptions.path == ApiPaths.userLogin,
      );
    }
    final writes = !const [
      'GET',
      'HEAD',
      'OPTIONS',
    ].contains(error.requestOptions.method.toUpperCase());
    return switch (error.type) {
      DioExceptionType.connectionTimeout => '连接服务器超时，请检查网络后重试',
      DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout =>
        writes ? '请求超时，操作结果尚未确认，请刷新相关记录后再操作' : '服务器响应超时，请稍后刷新',
      DioExceptionType.connectionError =>
        writes ? '网络连接中断，操作结果尚未确认，请检查网络并刷新相关记录' : '无法连接服务器，请检查网络或服务器地址',
      DioExceptionType.badCertificate => '无法验证服务器安全证书，请联系平台处理',
      DioExceptionType.cancel => '请求已取消',
      _ => fallback,
    };
  }
  if (error is PlatformException) {
    return switch (error.code.toLowerCase()) {
      'camera_access_denied' ||
      'camera_access_denied_without_prompt' => '未获得相机权限，请在系统设置中允许相机访问',
      'photo_access_denied' ||
      'photo_access_denied_without_prompt' ||
      'read_external_storage_denied' => '未获得照片访问权限，请在系统设置中允许访问照片',
      'camera_access_restricted' ||
      'photo_access_restricted' => '系统限制了相机或照片访问，请检查设备权限设置',
      _ => fallback,
    };
  }
  if (error is FormatException || error is TypeError) {
    return '服务返回的数据格式异常，请稍后重试';
  }
  return fallback;
}

bool _isUseful(String text) {
  if (text.isEmpty || text.length > 240) return false;
  if (const {
    '操作成功',
    '请求失败',
    '操作失败',
    '发送失败',
    '加载失败',
    '登录失败',
    '注册失败',
    '绑定失败',
    '解绑失败',
    '保存失败',
    '网络请求失败',
    '系统内部错误',
    '请求参数不合法',
    'Bad Request',
    'Unauthorized',
    'Forbidden',
    'Internal Server Error',
  }.contains(text)) {
    return false;
  }
  // Never display response pages, stack traces, or transport diagnostics.
  return !RegExp(
    r'<[^>]+>|DioException|SocketException|Exception:|StackTrace|[\r\n]|https?://|Bearer\s',
    caseSensitive: false,
  ).hasMatch(text);
}
