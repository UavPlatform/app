import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

/// REQ-SHIP-EXEC-004: read-only server-persisted telemetry, never synthetic values.
class DispatchFlightApi {
  DispatchFlightApi(this.client);
  final HttpClient client;
  Future<ApiFlightViewVO> current(String id) async {
    final raw = await dispatchRequest(
      () => client.dio.get(ApiPaths.dispatchOrdersFlightPath(id)),
    );
    final v = ApiFlightViewVO.fromJson(raw as Map<String, dynamic>);
    if (v.stale == null ||
        (v.connection != null && v.connection!.orderId != id)) {
      throw const DispatchApiException('飞行状态未确认，请重试');
    }
    return v;
  }

  Future<ApiFlightTrackVO> track(String id, int after) async {
    final raw = await dispatchRequest(
      () => client.dio.get(
        ApiPaths.dispatchOrdersFlightTrackPath(id),
        queryParameters: ApiPaths.dispatchOrdersFlightTrackQuery(after: after),
      ),
    );
    final v = ApiFlightTrackVO.fromJson(raw as Map<String, dynamic>);
    if (v.items == null ||
        v.hasNext == null ||
        v.nextAfter == null ||
        v.nextAfter! < after ||
        (v.hasNext! && v.nextAfter == after) ||
        v.items!.any(
          (s) =>
              s.sampleId == null ||
              s.sampleId! <= after ||
              s.connectionId == null ||
              s.sequence == null,
        )) {
      throw const DispatchApiException('轨迹数据未确认，请重试');
    }
    return v;
  }
}
