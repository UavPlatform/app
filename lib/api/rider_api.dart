import 'http_client.dart';
import '../models/result_model.dart';
import '../models/rider_vo.dart';

class RiderApi {
  final HttpClient _client;

  RiderApi(this._client);

  Future<Result<List<RiderVo>>> getRecommended() async {
    final response = await _client.dio.get('/rider/recommended');
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
