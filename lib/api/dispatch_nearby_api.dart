import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';
import '../services/dispatch_location.dart';
import '../models/dispatch_order.dart';

class DispatchNearbyApi {
  DispatchNearbyApi(this.client);
  final HttpClient client;
  Future<String> begin() async {
    final key = await dispatchRequest(
      () => client.dio.post(ApiPaths.dispatchPilotPositionSession),
    );
    if (key is! String || key.isEmpty) {
      throw const DispatchApiException('附近接单开启未确认');
    }
    return key;
  }

  Future<ApiDispatchPositionVO> update(
    DispatchLocationFix fix,
    String sessionKey,
  ) async {
    if (!fix.validAt(DateTime.now())) {
      throw const DispatchApiException('定位已过期或无效');
    }
    final raw = await dispatchRequest(
      () => client.dio.put(
        ApiPaths.dispatchPilotPosition,
        data: ApiDispatchPositionDTO(
          sessionKey: sessionKey,
          latitude: fix.latitude!,
          longitude: fix.longitude!,
          accuracyMeters: fix.accuracyMeters!,
          capturedAt: fix.capturedAt!,
          coordinateSystem: fix.coordinateSystem!,
          mocked: fix.mocked!,
        ).toJson(),
      ),
    );
    final result = ApiDispatchPositionVO.fromJson(raw as Map<String, dynamic>);
    if (result.coordinateSystem != 'GCJ02' ||
        result.receivedAt == null ||
        (result.expiresAt ?? 0) <= DateTime.now().millisecondsSinceEpoch ||
        result.accuracyMeters == null) {
      throw const DispatchApiException('位置更新未确认，请重试');
    }
    return result;
  }

  Future<void> clear([String? sessionKey]) async {
    await dispatchRequest(
      () => client.dio.delete(
        ApiPaths.deleteDispatchPilotPosition,
        queryParameters: ApiPaths.deleteDispatchPilotPositionQuery(
          sessionKey: sessionKey,
        ),
      ),
      allowEmpty: true,
    );
  }

  Future<ApiDispatchNearbyHallVO> hall(int page) async {
    final raw = await dispatchRequest(
      () => client.dio.get(
        ApiPaths.dispatchPilotNearbyHall,
        queryParameters: ApiPaths.dispatchPilotNearbyHallQuery(page: page),
      ),
    );
    final result = ApiDispatchNearbyHallVO.fromJson(
      raw as Map<String, dynamic>,
    );
    if (result.page != page ||
        result.items == null ||
        result.hasNext == null ||
        (result.radiusKm ?? 0) <= 0 ||
        !const ['READY', 'LOCATION_REQUIRED'].contains(result.locationState)) {
      throw const DispatchApiException('附近订单返回不完整');
    }
    if (result.locationState == 'LOCATION_REQUIRED' &&
        result.items!.isNotEmpty) {
      throw const DispatchApiException('附近位置状态无效');
    }
    if (result.locationState == 'READY' &&
        (result.locationExpiresAt ?? 0) <=
            DateTime.now().millisecondsSinceEpoch) {
      throw const DispatchApiException('附近位置已过期，请重新定位');
    }
    for (final item in result.items!) {
      if (item.offer == null ||
          item.distanceMeters == null ||
          !item.distanceMeters!.isFinite ||
          item.distanceMeters! < 0 ||
          item.distanceMeters! > result.radiusKm! * 1000) {
        throw const DispatchApiException('附近距离无效');
      }
      DispatchOffer(item.offer!);
    }
    return result;
  }

  Future<ApiDispatchNearbyStatusVO> status(String id) async {
    final raw = await dispatchRequest(
      () => client.dio.get(ApiPaths.dispatchOrdersNearbyDispatchPath(id)),
    );
    final result = ApiDispatchNearbyStatusVO.fromJson(
      raw as Map<String, dynamic>,
    );
    if (result.orderId != id ||
        (result.assignmentVersion ?? -1) < 0 ||
        (result.notifiedPilotCount ?? -1) < 0 ||
        (result.radiusKm ?? 0) <= 0 ||
        result.reminderSent == null ||
        result.systemPushEnabled != false) {
      throw const DispatchApiException('附近派单进度未确认，请重新查询');
    }
    return result;
  }
}
