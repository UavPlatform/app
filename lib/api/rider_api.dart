import 'http_client.dart';
import '../models/result_model.dart';
import '../models/task_vo.dart';
import '../models/rider_stats_vo.dart';

class RiderApi {
  final HttpClient _client;

  RiderApi(this._client);

  /// 任务广场 - 查看所有可接的任务
  Future<Result<TaskPageVo>> listAvailableTasks() async {
    final response = await _client.dio.get('/rider/square');
    return TaskPageVo.parseResult(response.data);
  }

  /// 接受任务
  Future<Result<void>> acceptTask(String taskNum) async {
    final response = await _client.dio.post(
      '/rider/accept',
      queryParameters: {'taskNum': taskNum},
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  /// 进行中的任务
  Future<Result<TaskPageVo>> getMyActiveTasks() async {
    final response = await _client.dio.get('/rider/my-tasks');
    return TaskPageVo.parseResult(response.data);
  }

  /// 全部接单历史
  Future<Result<TaskPageVo>> getMyAllTasks() async {
    final response = await _client.dio.get('/rider/my-tasks/history');
    return TaskPageVo.parseResult(response.data);
  }

  /// 取消接单
  Future<Result<void>> cancelTask(String taskNum) async {
    final response = await _client.dio.post(
      '/rider/cancel',
      queryParameters: {'taskNum': taskNum},
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
      '/rider/complete',
      queryParameters: {'taskNum': taskNum},
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
    final response = await _client.dio.get('/rider/stats');
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
    final response = await _client.dio.get('/rider/recommended');
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = (data['data'] as List<dynamic>)
          .map((e) => RiderStatsVo.fromJson(e as Map<String, dynamic>))
          .toList();
      return Result(success: true, code: 200, data: list);
    }
    return Result(success: false, code: data['code'], message: data['message'] as String?);
  }
}
