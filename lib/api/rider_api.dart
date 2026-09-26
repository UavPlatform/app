import 'package:dio/dio.dart';
import 'http_client.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import '../models/result_model.dart';
import '../models/rider_vo.dart';
import '../models/task_vo.dart';
import '../models/rider_stats_vo.dart';
import '../models/task_application_vo.dart';

class RiderApi {
  final HttpClient _client;

  RiderApi(this._client);

  /// 任务广场 - 查看所有可接的任务
  Future<Result<TaskPageVo>> listAvailableTasks() async {
    final response = await _client.dio.get(ApiPaths.riderSquare);
    return TaskPageVo.parseResult(response.data);
  }

  /// 飞手任务详情（GET /rider/task/detail）：无需任务归属，
  /// 返回含撮合状态、货物字段与订单/报价回显的完整 VO。
  Future<Result<TaskVo>> getTaskDetail(String taskNum) async {
    final response = await _client.dio.get(
      ApiPaths.riderTaskDetail,
      queryParameters: ApiPaths.riderTaskDetailQuery(taskNum: taskNum),
    );
    return TaskVo.parseResult(response.data);
  }

  /// 飞手应征（POST /rider/apply）：仅提交 taskNum + aircraftModelId，
  /// 服务端按 ADR-0003 平台计价返回系统报价 quotedAmount（客户端不传金额，无法改价）。
  ///
  /// 后端业务失败（EXCEEDS_PAYLOAD / AIRCRAFT_MODEL_* / UAV_NOT_FOUND /
  /// MATCH_STATUS_INVALID 等）以非 2xx 返回，此处捕获并映射为 Result，
  /// 保留 errorCode/message 供 UI 展示明确拒绝原因。
  Future<Result<TaskApplicationVo>> apply({
    required String taskNum,
    required int aircraftModelId,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.riderApply,
        queryParameters: ApiPaths.riderApplyQuery(
          taskNum: taskNum,
          aircraftModelId: aircraftModelId,
        ),
        data: ApiRiderApplyDto(
          taskNum: taskNum,
          aircraftModelId: aircraftModelId,
        ).toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return Result(
          success: true,
          code: data['code'] as int?,
          data: TaskApplicationVo.fromJson(
            data['data'] as Map<String, dynamic>,
          ),
        );
      }
      return Result(
        success: false,
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
          message: body['message'] as String? ?? '应征失败，请稍后重试',
        );
      }
      return Result(success: false, message: '应征失败，请检查网络后重试');
    }
  }

  /// 飞手确认订单（POST /rider/confirm-order）：确认约定作业时间，
  /// 双确认齐备后服务端推进 IN_PROGRESS（可执飞）。同样映射业务失败信封。
  Future<Result<TaskVo>> confirmOrder(String taskNum) async {
    try {
      final response = await _client.dio.post(
        ApiPaths.riderConfirmOrder,
        queryParameters: ApiPaths.riderConfirmOrderQuery(taskNum: taskNum),
      );
      return TaskVo.parseResult(response.data as Map<String, dynamic>);
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
