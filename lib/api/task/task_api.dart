import '../auth/http_client.dart';
import '../../models/amap_config.dart';
import '../../models/result_model.dart';

class TaskApi {
  final HttpClient _client;

  TaskApi(this._client);

  Future<Result<AmapConfig>> getAmapConfig() async {
    final response = await _client.dio.get('/task/init');
    return AmapConfig.parseResult(response.data);
  }
}
