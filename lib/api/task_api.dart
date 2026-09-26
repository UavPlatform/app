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

  Future<Result<void>> confirmTask(String taskNum) async {
    final response = await _client.dio.post(
      ApiPaths.taskConfirm,
      queryParameters: ApiPaths.taskConfirmQuery(taskNum: taskNum),
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }
}
