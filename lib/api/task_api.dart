import 'http_client.dart';
import '../models/amap_config.dart';
import '../models/result_model.dart';
import '../models/create_task_request.dart';
import '../models/task_vo.dart';

class TaskApi {
  final HttpClient _client;

  TaskApi(this._client);

  Future<Result<AmapConfig>> getAmapConfig() async {
    final response = await _client.dio.get('/task/init');
    return AmapConfig.parseResult(response.data);
  }

  Future<Result<TaskVo>> createTask(CreateTaskRequest request) async {
    final response = await _client.dio.post(
      '/task/create',
      data: request.toJson(),
    );
    return TaskVo.parseResult(response.data);
  }

  Future<Result<TaskPageVo>> listTasks({int page = 0, int size = 20}) async {
    final response = await _client.dio.get(
      '/task/list',
      queryParameters: {'page': page, 'size': size},
    );
    return TaskPageVo.parseResult(response.data);
  }

  Future<Result<TaskVo>> getTaskDetail(String taskNum) async {
    final response = await _client.dio.get(
      '/task/detail',
      queryParameters: {'taskNum': taskNum},
    );
    return TaskVo.parseResult(response.data);
  }

  Future<Result<void>> deleteTask(int taskId) async {
    final response = await _client.dio.delete(
      '/task/delete',
      queryParameters: {'id': taskId},
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
      '/task/confirm',
      queryParameters: {'taskNum': taskNum},
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }
}
