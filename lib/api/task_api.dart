import 'http_client.dart';
import 'generated/openapi_paths.dart';
import '../models/amap_config.dart';
import '../models/result_model.dart';
import '../models/create_task_request.dart';
import '../models/task_vo.dart';

class TaskApi {
  final HttpClient _client;

  TaskApi(this._client);

  Future<Result<AmapConfig>> getAmapConfig() async {
    final response = await _client.dio.get(ApiPaths.taskInit);
    return AmapConfig.parseResult(response.data);
  }

  Future<Result<TaskVo>> createTask(CreateTaskRequest request) async {
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
