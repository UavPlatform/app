import 'package:uav_pilot_app/api/equipment_api.dart';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';

Map<String, dynamic> equipmentDrone({
  bool mine = false,
  bool borrowed = false,
}) => {
  'droneId': 'drone1',
  'aircraftModelId': 1,
  'modelName': 'FC30',
  'serialNumber': 'TEST-SERIAL',
  'airportId': 1,
  'airportName': '测试场地',
  'enabled': true,
  'borrowed': borrowed || mine,
  'borrowedByMe': mine,
  'currentBorrowId': mine ? 'loan1' : null,
};

Map<String, dynamic> equipmentLoan({
  String status = 'PENDING',
  bool withDrone = false,
  bool returned = false,
  bool alreadyHas = false,
}) => {
  'borrowId': 'loan1',
  'status': status,
  'aircraftModelId': 1,
  'modelName': 'FC30',
  'pilotId': 7,
  'appliedAt': '2026-10-23T09:00:00',
  'borrowedAt': status == 'APPROVED' || status == 'RETURNED'
      ? '2026-10-23T10:00:00'
      : null,
  'returnedAt': returned || status == 'RETURNED' ? '2026-10-23T11:00:00' : null,
  'rejectReason': status == 'REJECTED' ? '库存不足' : null,
  'alreadyHasActiveLoan': alreadyHas,
  'drone': withDrone || status == 'APPROVED' || status == 'RETURNED'
      ? equipmentDrone(mine: status == 'APPROVED')
      : null,
};

class FakeEquipmentApi extends EquipmentApi {
  FakeEquipmentApi(super.client);
  bool active = false;
  bool returned = false;
  bool loseResponse = true;
  final keys = <String>[];
  int? lastModelId;

  ApiDroneBorrowVO get pending =>
      ApiDroneBorrowVO.fromJson(equipmentLoan(status: 'PENDING'));
  ApiDroneBorrowVO get approved => ApiDroneBorrowVO.fromJson(
    equipmentLoan(status: 'APPROVED', withDrone: true),
  );
  ApiDroneBorrowVO get loan => ApiDroneBorrowVO.fromJson(
    equipmentLoan(
      status: returned ? 'RETURNED' : (active ? 'APPROVED' : 'PENDING'),
      withDrone: active || returned,
      returned: returned,
    ),
  );

  @override
  Future<ApiProviderDronePageVO> catalog(int page) async =>
      ApiProviderDronePageVO(
        items: [ApiProviderDroneVO.fromJson(equipmentDrone(mine: active))],
        page: page,
        hasNext: false,
      );

  @override
  Future<ApiModelStockVO> modelStock() async => ApiModelStockVO(
    items: [
      ApiItem(
        aircraftModelId: 1,
        modelName: 'FC30',
        modelCode: 'FC30',
        inStockCount: active ? 0 : 2,
      ),
      const ApiItem(
        aircraftModelId: 2,
        modelName: '空库机型',
        modelCode: 'EMPTY',
        inStockCount: 0,
      ),
    ],
  );

  @override
  Future<ApiDroneBorrowPageVO> mine(int page) async => ApiDroneBorrowPageVO(
    items: active || returned ? [loan] : [],
    page: page,
    hasNext: false,
  );

  @override
  Future<ApiDroneBorrowPageVO> current() async => ApiDroneBorrowPageVO(
    items: active ? [approved] : [],
    page: 0,
    hasNext: false,
  );

  @override
  Future<ApiDroneBorrowVO> apply({
    required int aircraftModelId,
    required String requestKey,
    String? orderId,
  }) async {
    keys.add(requestKey);
    lastModelId = aircraftModelId;
    if (loseResponse) {
      loseResponse = false;
      throw const DispatchApiException('申请响应丢失');
    }
    return pending;
  }

  @override
  Future<ApiDroneBorrowVO> giveBack(String id) async {
    active = false;
    returned = true;
    return ApiDroneBorrowVO.fromJson(
      equipmentLoan(status: 'RETURNED', withDrone: true, returned: true),
    );
  }
}
