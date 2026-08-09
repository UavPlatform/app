import 'http_client.dart';
import '../models/amap_config.dart';
import '../models/result_model.dart';
import '../models/create_task_request.dart';
import '../models/price_detail.dart';
import '../models/publish_config.dart';
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

  /// 发布前预览参考价（与创建任务同口径）
  Future<Result<PriceDetail>> estimatePrice(PriceEstimateRequest request) async {
    final response = await _client.dio.post(
      '/task/price/estimate',
      data: request.toJson(),
    );
    return PriceDetail.parseResult(response.data);
  }

  /// 发布页配置（重量计费类型、协商价下限）
  Future<Result<PublishConfig>> getPublishConfig() async {
    final response = await _client.dio.get('/task/publish/config');
    return PublishConfig.parseResult(response.data);
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
