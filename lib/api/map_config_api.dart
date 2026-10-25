// 高德地图配置：GET /config/map（需求方/飞手/管理员均可，backend#47）。
// 原生端只拿 key，后端不下发 securityKey。

import '../models/amap_config.dart';
import '../models/result_model.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class MapConfigApi {
  final HttpClient _client;

  MapConfigApi(this._client);

  Future<Result<AmapConfig>> getAmapConfig() async {
    final response = await _client.dio.get(ApiPaths.configMap);
    return AmapConfig.parseResult(response.data);
  }
}
