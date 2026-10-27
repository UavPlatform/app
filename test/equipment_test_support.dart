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

class FakeEquipmentApi extends EquipmentApi {
  FakeEquipmentApi(super.client);
  bool active = false;
  bool returned = false;
  bool loseResponse = true;
  final keys = <String>[];
  ApiDroneBorrowVO get loan => ApiDroneBorrowVO(
    borrowId: 'loan1',
    pilotId: 7,
    borrowedAt: '2026-10-23T10:00:00',
    returnedAt: returned ? '2026-10-23T11:00:00' : null,
    drone: ApiProviderDroneVO.fromJson(equipmentDrone(mine: active)),
  );
  @override
  Future<ApiProviderDronePageVO> catalog(int page) async =>
      ApiProviderDronePageVO(
        items: [ApiProviderDroneVO.fromJson(equipmentDrone(mine: active))],
        page: page,
        hasNext: false,
      );
  @override
  Future<ApiDroneBorrowPageVO> mine(int page) async => ApiDroneBorrowPageVO(
    items: active || returned ? [loan] : [],
    page: page,
    hasNext: false,
  );
  @override
  Future<ApiDroneBorrowVO> borrow(String droneId, String key) async {
    keys.add(key);
    active = true;
    if (loseResponse) {
      loseResponse = false;
      throw const DispatchApiException('登记响应丢失');
    }
    return loan;
  }

  @override
  Future<ApiDroneBorrowVO> giveBack(String id) async {
    active = false;
    returned = true;
    return loan;
  }
}
