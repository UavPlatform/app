import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class EquipmentApi {
  EquipmentApi(this.client);
  final HttpClient client;
  void _drone(ApiProviderDroneVO d) {
    if ((d.droneId ?? '').isEmpty ||
        (d.serialNumber ?? '').isEmpty ||
        d.enabled == null ||
        d.borrowed == null ||
        d.borrowedByMe == null ||
        (d.borrowedByMe! &&
            (!d.borrowed! || (d.currentBorrowId ?? '').isEmpty))) {
      throw const DispatchApiException('设备信息不完整，请刷新');
    }
  }

  ApiDroneBorrowVO _borrow(dynamic raw) {
    final result = ApiDroneBorrowVO.fromJson(raw as Map<String, dynamic>);
    if ((result.borrowId ?? '').isEmpty ||
        result.drone == null ||
        result.borrowedAt == null) {
      throw const DispatchApiException('借还结果未确认，请刷新本人记录');
    }
    _drone(result.drone!);
    return result;
  }

  Future<ApiProviderDronePageVO> catalog(int page) async {
    final raw = await dispatchRequest(
      () => client.dio.get(
        ApiPaths.equipmentPilotDrones,
        queryParameters: ApiPaths.equipmentPilotDronesQuery(
          page: page.toString(),
        ),
      ),
    );
    final result = ApiProviderDronePageVO.fromJson(raw as Map<String, dynamic>);
    if (result.page != page || result.items == null || result.hasNext == null) {
      throw const DispatchApiException('设备目录未确认，请重试');
    }
    for (final item in result.items!) {
      _drone(item);
    }
    return result;
  }

  Future<ApiDroneBorrowPageVO> mine(int page) async {
    final raw = await dispatchRequest(
      () => client.dio.get(
        ApiPaths.equipmentPilotBorrows,
        queryParameters: ApiPaths.equipmentPilotBorrowsQuery(
          page: page.toString(),
        ),
      ),
    );
    final result = ApiDroneBorrowPageVO.fromJson(raw as Map<String, dynamic>);
    if (result.page != page || result.items == null || result.hasNext == null) {
      throw const DispatchApiException('借还记录未确认，请重试');
    }
    for (final item in result.items!) {
      _borrow(item.toJson());
    }
    return result;
  }

  Future<ApiDroneBorrowVO> borrow(String droneId, String key) async {
    final result = _borrow(
      await dispatchRequest(
        () => client.dio.post(
          ApiPaths.postEquipmentPilotBorrows,
          data: ApiDroneBorrowDTO(droneId: droneId, requestKey: key).toJson(),
        ),
      ),
    );
    if (result.drone!.droneId != droneId ||
        (result.returnedAt == null &&
            result.drone!.currentBorrowId != result.borrowId)) {
      throw const DispatchApiException('借用结果与本次登记不符，请查询本人记录');
    }
    return result;
  }

  Future<ApiDroneBorrowVO> giveBack(String borrowId) async {
    final result = _borrow(
      await dispatchRequest(
        () =>
            client.dio.post(ApiPaths.equipmentPilotBorrowsReturnPath(borrowId)),
      ),
    );
    if (result.borrowId != borrowId || result.returnedAt == null) {
      throw const DispatchApiException('归还尚未确认，请刷新本人记录');
    }
    return result;
  }
}
