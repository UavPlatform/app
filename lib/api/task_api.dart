import 'package:dio/dio.dart';

import 'http_client.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import '../models/amap_config.dart';
import '../models/result_model.dart';
import '../models/task_application_vo.dart';
import '../models/task_vo.dart';

class TaskApi {
  final HttpClient _client;

  TaskApi(this._client);

  Future<Result<AmapConfig>> getAmapConfig() async {
    final response = await _client.dio.get(ApiPaths.taskInit);
    return AmapConfig.parseResult(response.data);
  }

  /// 发单（契约生成模型 ApiTaskDto 直发：货物字段与 waypoint 均来自 OpenAPI）。
  Future<Result<TaskVo>> createTask(ApiTaskDto request) async {
    final response = await _client.dio.post(
      ApiPaths.taskCreate,
      data: request.toJson(),
    );
    return TaskVo.parseResult(response.data);
  }

  Future<Result<TaskPageVo>> listTasks({int page = 0, int size = 20}) async {
    final response = await _client.dio.get(
      ApiPaths.taskList,
      queryParameters: ApiPaths.taskListQuery(page: page, size: size),
    );
    return TaskPageVo.parseResult(response.data);
  }

  Future<Result<TaskVo>> getTaskDetail(String taskNum) async {
    final response = await _client.dio.get(
      ApiPaths.taskDetail,
      queryParameters: ApiPaths.taskDetailQuery(taskNum: taskNum),
    );
    return TaskVo.parseResult(response.data);
  }

  /// 应征列表（GET /task/{taskNum}/applications，任务属主可见）：
  /// 飞手 + 机型 + 载重 + 系统报价 quotedAmount + 应征时间。
  Future<Result<List<TaskApplicationVo>>> listApplications(
      String taskNum) async {
    final response =
        await _client.dio.get(ApiPaths.taskApplicationsPath(taskNum));
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => TaskApplicationVo.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(
      success: false,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  /// 用户选定飞手并下单（POST /task/{taskNum}/select-rider）：
  /// 只提交 applicationId + 约定作业时间，金额由服务端锁定为该应征的
  /// 系统报价 quotedAmount（ADR-0003 禁止改价，客户端不传任何金额字段）。
  /// 成功后该应征 SELECTED、其余应征 CLOSED，订单 totalAmount = quotedAmount。
  Future<Result<TaskVo>> selectRider({
    required String taskNum,
    required int applicationId,
    required String scheduledTime,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.taskSelectRiderPath(taskNum),
        data: ApiSelectRiderDto(
          applicationId: applicationId,
          scheduledTime: scheduledTime,
        ).toJson(),
      );
      return TaskVo.parseResult(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        return Result(
          success: false,
          code: body['code'] as int?,
          errorCode: body['errorCode'] as String?,
          message: body['message'] as String? ?? '选定飞手失败，请稍后重试',
        );
      }
      return Result(success: false, message: '选定飞手失败，请检查网络后重试');
    }
  }

  Future<Result<void>> deleteTask(int taskId) async {
    final response = await _client.dio.delete(
      ApiPaths.taskDelete,
      queryParameters: ApiPaths.taskDeleteQuery(id: taskId),
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  /// 用户确认完成（POST /task/confirm）：服务端要求 ≥1 履约证据，
  /// 无证据时返回 DELIVERY_EVIDENCE_REQUIRED，业务失败信封原样透出供 UI 展示。
  Future<Result<void>> confirmTask(String taskNum) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.taskConfirm,
        queryParameters: ApiPaths.taskConfirmQuery(taskNum: taskNum),
      );
      final data = response.data as Map<String, dynamic>;
      return Result(
        success: data['success'] == true,
        code: data['code'] as int?,
        errorCode: data['errorCode'] as String?,
        message: data['message'] as String?,
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        return Result(
          success: false,
          code: body['code'] as int?,
          errorCode: body['errorCode'] as String?,
          message: body['message'] as String? ?? '确认失败，请稍后重试',
        );
      }
      return Result(success: false, message: '确认失败，请检查网络后重试');
    }
  }
}
