import 'package:dio/dio.dart';

import 'http_client.dart';
import 'generated/openapi_paths.dart';
import '../models/result_model.dart';
import '../models/rider_vo.dart';
import '../models/task_vo.dart';
import '../models/rider_stats_vo.dart';

class RiderApi {
  final HttpClient _client;

  RiderApi(this._client);

  /// 任务广场 - 查看所有可接的任务
  Future<Result<TaskPageVo>> listAvailableTasks() async {
    final response = await _client.dio.get(ApiPaths.riderSquare);
    return TaskPageVo.parseResult(response.data);
  }

  /// 接受任务
  /// 后端业务失败以非 2xx 返回（如 t22 TASK_NOT_PAID：任务订单未支付），
  /// 此处捕获并映射为 Result，保留 errorCode 供上层展示明确提示。
  Future<Result<void>> acceptTask(String taskNum) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.riderAccept,
        queryParameters: ApiPaths.riderAcceptQuery(taskNum: taskNum),
      );
      final data = response.data as Map<String, dynamic>;
      return Result(
        success: data['success'] == true,
        code: data['code'] as int?,
        errorCode: data['errorCode'] as String?,
        message: data['message'] as String?,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return Result(
          success: data['success'] == true,
          code: data['code'] as int?,
          errorCode: data['errorCode'] as String?,
          message: data['message'] as String? ?? '接单失败，请稍后重试',
        );
      }
      return Result(success: false, message: '接单失败，请检查网络后重试');
    }
  }

  /// 进行中的任务
  Future<Result<TaskPageVo>> getMyActiveTasks() async {
    final response = await _client.dio.get(ApiPaths.riderMyTasks);
    return TaskPageVo.parseResult(response.data);
  }

  /// 全部接单历史
  Future<Result<TaskPageVo>> getMyAllTasks() async {
    final response = await _client.dio.get(ApiPaths.riderMyTasksHistory);
    return TaskPageVo.parseResult(response.data);
  }

  /// 取消接单
  Future<Result<void>> cancelTask(String taskNum) async {
    final response = await _client.dio.post(
      ApiPaths.riderCancel,
      queryParameters: ApiPaths.riderCancelQuery(taskNum: taskNum),
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  /// 完成任务
  Future<Result<void>> completeTask(String taskNum) async {
    final response = await _client.dio.post(
      ApiPaths.riderComplete,
      // 契约 builder 含可选 note；本端不传 note，剔除 null 键以保持既有请求 query 不变。
      queryParameters: ApiPaths.riderCompleteQuery(taskNum: taskNum)
        ..removeWhere((key, value) => value == null),
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  /// 飞手统计
  Future<Result<RiderStatsVo>> getRiderStats() async {
    final response = await _client.dio.get(ApiPaths.riderStats);
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      return Result(
        success: true,
        code: 200,
        data: RiderStatsVo.fromJson(data['data'] as Map<String, dynamic>),
      );
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  /// 推荐飞手列表
  Future<Result<List<RiderStatsVo>>> getRecommendedRiders() async {
    final response = await _client.dio.get(ApiPaths.riderRecommended);
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => RiderStatsVo.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }

  /// 推荐飞手（远端并行功能线：首页热门飞手）
  Future<Result<List<RiderVo>>> getRecommended() async {
    final response = await _client.dio.get(ApiPaths.riderRecommended);
    final data = response.data as Map<String, dynamic>;
    final code = data['code'] as int?;
    if (code == 200 && data['data'] != null) {
      final list = (data['data'] as List)
          .map((e) => RiderVo.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: code, message: data['message'] as String?, data: list);
    }
    return Result(success: false, code: code, message: data['message'] as String?);
  }
}
