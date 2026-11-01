import '../utils/failure_message.dart';
// 飞手资料接口（GET/PATCH /rider/info）：实名信息（身份证号仅回脱敏值）、证件有效期、
// 所在地/自我介绍与驾驶资质（机型 × 执照等级）。PATCH 局部更新：字段为 null 不修改，
// qualifications 传数组时按机型做集合差异（[] 清空）。

import 'package:dio/dio.dart';

import '../models/result_model.dart';
import 'http_client.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';

/// 执照等级（后端 LicenseGrade 枚举）→ 中文标签。
const Map<String, String> kLicenseGradeLabels = {
  'VLOS': '视距内',
  'BVLOS': '超视距',
  'TEACHER': '教员',
};

class RiderInfoApi {
  final HttpClient _client;

  RiderInfoApi(this._client);

  Future<Result<ApiRiderInfoVO>> getInfo() async {
    try {
      final response = await _client.dio.get(ApiPaths.riderInfo);
      return Result.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ApiRiderInfoVO.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _failure(e, '飞手资料加载失败');
    }
  }

  Future<Result<ApiRiderInfoVO>> editInfo(ApiRiderInfoDto dto) async {
    try {
      final body = dto.toJson();
      // 生成模型的 toJson 对嵌套列表不展开，这里显式转成 Map，避免依赖编码器隐式调用 toJson。
      if (dto.qualifications != null) {
        body['qualifications'] = dto.qualifications!
            .map((q) => q.toJson())
            .toList();
      }
      final response = await _client.dio.patch(ApiPaths.riderInfo, data: body);
      return Result.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ApiRiderInfoVO.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _failure(e, '保存失败，请稍后重试');
    }
  }

  Result<T> _failure<T>(DioException e, String fallback) {
    final data = e.response?.data;
    return Result(
      success: false,
      code: data is Map && data['code'] is int
          ? data['code'] as int
          : e.response?.statusCode,
      errorCode: data is Map && data['errorCode'] is String
          ? data['errorCode'] as String
          : null,
      message: failureMessage(e, fallback: fallback),
    );
  }
}
