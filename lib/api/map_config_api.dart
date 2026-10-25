// 高德地图配置：后端目前仍只在 GET /task/init 下发 key/securityKey。
// 旧撮合 task_api 已删除，此处单独保留该读取；后端删除旧 TaskController 前需迁移该端点。

import '../models/amap_config.dart';
import '../models/result_model.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class MapConfigApi {
  final HttpClient _client;

  MapConfigApi(this._client);

  Future<Result<AmapConfig>> getAmapConfig() async {
    final response = await _client.dio.get(ApiPaths.taskInit);
    return AmapConfig.parseResult(response.data);
  }
}
