import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

/// REQ-PILOT-EXEC-005：飞手按机型申请、查看申请/借出、主动归还。
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

  ApiDroneBorrowVO _loan(dynamic raw, {bool requireReturned = false}) {
    final result = ApiDroneBorrowVO.fromJson(raw as Map<String, dynamic>);
    final status = result.status ?? '';
    if ((result.borrowId ?? '').isEmpty || status.isEmpty) {
      throw const DispatchApiException('借还结果未确认，请刷新本人记录');
    }
    if (requireReturned) {
      if (status != 'RETURNED' || result.returnedAt == null) {
        throw const DispatchApiException('归还尚未确认，请刷新本人记录');
      }
      return result;
    }
    switch (status) {
      case 'PENDING':
        if (result.aircraftModelId == null ||
            (result.modelName ?? '').isEmpty ||
            result.appliedAt == null) {
          throw const DispatchApiException('申请结果未确认，请刷新本人记录');
        }
      case 'APPROVED':
        if (result.drone == null || result.borrowedAt == null) {
          throw const DispatchApiException('借出结果未确认，请刷新本人记录');
        }
        _drone(result.drone!);
      case 'REJECTED':
        if (result.appliedAt == null) {
          throw const DispatchApiException('驳回结果未确认，请刷新本人记录');
        }
      case 'RETURNED':
        if (result.returnedAt == null) {
          throw const DispatchApiException('归还结果未确认，请刷新本人记录');
        }
      default:
        throw DispatchApiException('未知申请状态：$status');
    }
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

  Future<ApiModelStockVO> modelStock() async {
    final raw = await dispatchRequest(
      () => client.dio.get(ApiPaths.equipmentPilotModelStock),
    );
    final result = ApiModelStockVO.fromJson(raw as Map<String, dynamic>);
    if (result.items == null) {
      throw const DispatchApiException('机型在库概况未确认，请重试');
    }
    for (final item in result.items!) {
      if (item.aircraftModelId == null ||
          (item.modelName ?? '').isEmpty ||
          item.inStockCount == null) {
        throw const DispatchApiException('机型在库概况不完整，请刷新');
      }
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
      throw const DispatchApiException('申请记录未确认，请重试');
    }
    for (final item in result.items!) {
      _loan(item.toJson());
    }
    return result;
  }

  Future<ApiDroneBorrowPageVO> current() async {
    final raw = await dispatchRequest(
      () => client.dio.get(ApiPaths.equipmentPilotBorrowsCurrent),
    );
    final result = ApiDroneBorrowPageVO.fromJson(raw as Map<String, dynamic>);
    if (result.items == null || result.hasNext == null) {
      throw const DispatchApiException('当前借出未确认，请重试');
    }
    for (final item in result.items!) {
      final loan = _loan(item.toJson());
      if (loan.status != 'APPROVED') {
        throw const DispatchApiException('当前借出列表含非已借出记录，请刷新');
      }
    }
    return result;
  }

  Future<ApiDroneBorrowVO> apply({
    required int aircraftModelId,
    required String requestKey,
    String? orderId,
  }) async {
    final result = _loan(
      await dispatchRequest(
        () => client.dio.post(
          ApiPaths.postEquipmentPilotBorrows,
          data: ApiDroneBorrowDTO(
            aircraftModelId: aircraftModelId,
            orderId: orderId,
            requestKey: requestKey,
          ).toJson(),
        ),
      ),
    );
    if (result.aircraftModelId != aircraftModelId) {
      throw const DispatchApiException('申请结果与所选机型不符，请查询本人记录');
    }
    return result;
  }

  Future<ApiDroneBorrowVO> giveBack(String borrowId) async {
    final result = _loan(
      await dispatchRequest(
        () =>
            client.dio.post(ApiPaths.equipmentPilotBorrowsReturnPath(borrowId)),
      ),
      requireReturned: true,
    );
    if (result.borrowId != borrowId) {
      throw const DispatchApiException('归还结果与本次登记不符，请刷新本人记录');
    }
    return result;
  }
}
