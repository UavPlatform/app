import 'http_client.dart';
import '../models/result_model.dart';
import '../models/address_vo.dart';

class AddressApi {
  final HttpClient _client;

  AddressApi(this._client);

  /// 当前用户地址列表（默认在前）
  Future<Result<List<AddressVo>>> listAddresses() async {
    final response = await _client.dio.get('/address/list');
    return AddressVo.parseListResult(response.data as Map<String, dynamic>);
  }

  Future<Result<AddressVo>> createAddress(Map<String, dynamic> json) async {
    final response = await _client.dio.post('/address/create', data: json);
    return AddressVo.parseResult(response.data as Map<String, dynamic>);
  }

  Future<Result<AddressVo>> updateAddress(Map<String, dynamic> json) async {
    final response = await _client.dio.put('/address/update', data: json);
    return AddressVo.parseResult(response.data as Map<String, dynamic>);
  }

  Future<Result<void>> deleteAddress(int id) async {
    final response = await _client.dio.delete(
      '/address/delete',
      queryParameters: {'id': id},
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }

  Future<Result<void>> setDefault(int id) async {
    final response = await _client.dio.put(
      '/address/default',
      queryParameters: {'id': id},
    );
    final data = response.data as Map<String, dynamic>;
    return Result(
      success: data['success'] == true,
      code: data['code'] as int?,
      message: data['message'] as String?,
    );
  }
}
