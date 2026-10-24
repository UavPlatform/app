import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class DispatchLiveApi {
  DispatchLiveApi(this.client);
  final HttpClient client;
  Future<ApiDispatchLiveStatusVO> status(String order) async {
    final raw = await dispatchRequest(
      () => client.dio.get(ApiPaths.dispatchOrdersLivePath(order)),
    );
    final s = ApiDispatchLiveStatusVO.fromJson(raw as Map<String, dynamic>);
    if (s.configured == null ||
        !{'UNAVAILABLE', 'STARTING', 'RUNNING'}.contains(s.state) ||
        (s.state != 'UNAVAILABLE' &&
            ((s.liveId ?? '').isEmpty ||
                (s.connectionId ?? '').isEmpty ||
                (s.leaseExpiresAt ?? 0) <= 0))) {
      throw const DispatchApiException('直播状态未确认');
    }
    return s;
  }

  Future<ApiDispatchLiveCredentialsVO> watch(
    String order,
    String liveId,
  ) async {
    final raw = await dispatchRequest(
      () =>
          client.dio.post(ApiPaths.dispatchOrdersLiveWatchPath(liveId, order)),
    );
    final c = ApiDispatchLiveCredentialsVO.fromJson(
      raw as Map<String, dynamic>,
    );
    if (c.liveId != liveId ||
        (c.sdkAppId ?? 0) <= 0 ||
        (c.roomId ?? '').isEmpty ||
        (c.userId ?? '').isEmpty ||
        (c.publisherUserId ?? '').isEmpty ||
        c.userId == c.publisherUserId ||
        (c.userSig ?? '').isEmpty ||
        (c.privateMapKey ?? '').isEmpty ||
        (c.connectionId ?? '').isEmpty ||
        (c.expiresAt ?? 0) <= 0) {
      throw const DispatchApiException('本单观看凭证未确认');
    }
    return c;
  }
}
