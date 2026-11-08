import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

/// REQ-SHIP-EXEC-004: read-only server-persisted telemetry, never synthetic values.
class DispatchFlightApi {
  DispatchFlightApi(this.client);
  final HttpClient client;
  Future<ApiFlightProjectionVO> current(String id) async {
    final raw = await dispatchRequest(
      () => client.dio.get(ApiPaths.dispatchOrdersFlightPath(id)),
    );
    final v = ApiFlightProjectionVO.fromJson(raw as Map<String, dynamic>);
    if (v.stale == null || v.projectionRevision == null) {
      throw const DispatchApiException('飞行状态未确认，请重试');
    }
    return v;
  }

  Future<ApiFlightEventPageVO> track(String id, int after) async {
    final raw = await dispatchRequest(
      () => client.dio.get(
        ApiPaths.dispatchOrdersFlightTrackPath(id),
        queryParameters: ApiPaths.dispatchOrdersFlightTrackQuery(after: after),
      ),
    );
    final v = ApiFlightEventPageVO.fromJson(raw as Map<String, dynamic>);
    if (v.items == null ||
        v.hasNext == null ||
        v.nextAfter == null ||
        v.nextAfter! < after ||
        (v.hasNext! && v.nextAfter == after) ||
        v.items!.any(
          (s) =>
              s.changeSequence == null ||
              s.changeSequence! <= after ||
              (s.eventId ?? '').isEmpty,
        )) {
      throw const DispatchApiException('轨迹数据未确认，请重试');
    }
    return v;
  }
}
