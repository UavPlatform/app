import 'package:dio/dio.dart';

import '../models/waybill_draft.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class DispatchApiException implements Exception {
  const DispatchApiException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

class DispatchSettings {
  const DispatchSettings({
    required this.currency,
    required this.depositAmount,
    required this.pilotServiceFee,
    required this.orderingEnabled,
  });
  final String currency;
  final double depositAmount;
  final double pilotServiceFee;
  final bool orderingEnabled;

  factory DispatchSettings.fromApi(ApiDispatchConfigVO value) {
    final deposit = value.depositAmount;
    final fee = value.pilotServiceFee;
    if (value.currency != 'CNY' ||
        deposit == null ||
        fee == null ||
        !deposit.isFinite ||
        !fee.isFinite ||
        deposit <= 0 ||
        fee <= 0 ||
        value.orderingEnabled == null) {
      throw const DispatchApiException('平台金额暂时无法获取，请重试');
    }
    return DispatchSettings(
      currency: value.currency!,
      depositAmount: deposit,
      pilotServiceFee: fee,
      orderingEnabled: value.orderingEnabled!,
    );
  }
}

class AccountWaybillDraft {
  const AccountWaybillDraft({required this.draft, required this.revision});
  final WaybillDraft draft;
  final int revision;

  factory AccountWaybillDraft.fromApi(ApiWaybillDraftVO value) {
    if (value.schemaVersion != 1 ||
        value.step == null ||
        value.step! < 0 ||
        value.step! > 4 ||
        value.revision == null ||
        value.revision! < 0 ||
        value.fields == null) {
      throw const DispatchApiException('账号草稿格式无效，未替换本机内容');
    }
    final fields = Map<String, String>.from(value.fields!);
    return AccountWaybillDraft(
      draft: WaybillDraft(fields: fields, step: value.step!),
      revision: value.revision!,
    );
  }
}

class DispatchApi {
  DispatchApi(this._client);
  final HttpClient _client;

  Future<Map<String, dynamic>?> _request(
    Future<Response<dynamic>> Function() send,
  ) async {
    try {
      final response = await send();
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw DispatchApiException(
          body['message'] as String? ?? '操作未完成，请重试',
          code: body['errorCode'] as String?,
        );
      }
      return body['data'] as Map<String, dynamic>?;
    } on DioException catch (error) {
      final body = error.response?.data;
      throw DispatchApiException(
        body is Map ? body['message'] as String? ?? '请求失败，请重试' : '连接失败，请稍后重试',
        code: body is Map ? body['errorCode'] as String? : null,
      );
    }
  }

  Future<DispatchSettings> settings() async {
    final data = await _request(() => _client.dio.get(ApiPaths.dispatchConfig));
    if (data == null) throw const DispatchApiException('平台金额暂时无法获取，请重试');
    return DispatchSettings.fromApi(ApiDispatchConfigVO.fromJson(data));
  }

  Future<AccountWaybillDraft?> loadDraft() async {
    final data = await _request(
      () => _client.dio.get(ApiPaths.dispatchWaybillDraft),
    );
    return data == null
        ? null
        : AccountWaybillDraft.fromApi(ApiWaybillDraftVO.fromJson(data));
  }

  Future<AccountWaybillDraft> saveDraft(
    WaybillDraft draft,
    int? revision,
  ) async {
    final request = ApiWaybillDraftDTO(
      schemaVersion: 1,
      step: draft.step,
      fields: draft.cloudFields,
      expectedRevision: revision,
    );
    final data = await _request(
      () => _client.dio.put(
        ApiPaths.putDispatchWaybillDraft,
        data: request.toJson(),
      ),
    );
    if (data == null) throw const DispatchApiException('未确认账号草稿保存成功，请重试');
    return AccountWaybillDraft.fromApi(ApiWaybillDraftVO.fromJson(data));
  }
}
