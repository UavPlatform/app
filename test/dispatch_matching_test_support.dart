import 'dart:async';
import 'package:uav_pilot_app/api/dispatch_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/dispatch_order.dart';
import '../test/dispatch_order_test_support.dart';

class FakeMatchingApi extends FakeDispatchOrderApi {
  FakeMatchingApi(super.client) {
    setStage('WAITING_ACCEPTANCE');
  }
  int claims = 0;
  int reads = 0;
  int epoch = 0;
  int revision = 1;
  bool failClaim = false;
  Completer<void>? claimGate;
  Completer<DispatchOrder>? readGate;
  void setStage(String stage) {
    order = DispatchOrder(
      ApiDispatchOrderVO.fromJson(
        orderJson(
            stage: stage,
            funds: stage == 'CANCELLED' ? 'REFUNDED' : 'PAID',
          )
          ..['assignedPilotId'] =
              ['PILOT_PREPARING', 'PILOT_ARRIVED', 'CANCELLED'].contains(stage)
              ? 77
              : null
          ..['assignmentVersion'] = epoch == 0 ? 1 : epoch
          ..['fields'] = {
            'category': '普通',
            'count': '2',
            'weightMin': '10',
            'weightMax': '20',
            'length': '30',
            'width': '20',
            'height': '10',
            'packaging': '木箱',
            'lifting': '双吊点',
            for (final side in ['start', 'end']) ...{
              '$side.site': '空地',
              '$side.lat': '28.2',
              '$side.lng': '113.0',
              '$side.landing': 'yes',
              '$side.contact': '现场联系人',
              '$side.phone': '13800000000',
            },
          },
      ),
    );
  }

  @override
  Future<DispatchHall> pilotHall(int page) async => DispatchHall(
    ApiDispatchHallVO.fromJson({
      'page': page,
      'hasNext': false,
      'items': order!.waiting
          ? [
              {
                'orderId': order!.id,
                'offerRevision': revision,
                'fields': {
                  'category': '普通',
                  'weightMin': '10',
                  'count': '2',
                  'timeMode': 'now',
                  'start.site': '空地',
                  'end.site': '空地',
                  'start.lat': '28.2',
                  'start.lng': '113.0',
                  'end.lat': '28.3',
                  'end.lng': '113.1',
                },
                'pilotServiceFee': 100,
              },
            ]
          : [],
    }),
  );
  @override
  Future<DispatchOrder> claim(String id, int revision) async {
    claims++;
    if (claimGate != null) await claimGate!.future;
    if (failClaim) {
      throw const DispatchApiException(
        '订单已被接走',
        code: 'DISPATCH_ASSIGNMENT_CHANGED',
      );
    }
    epoch++;
    setStage('PILOT_PREPARING');
    return order!;
  }

  @override
  Future<DispatchOrder> pilotGet(String id) async => order!;
  @override
  Future<List<DispatchOrder>> pilotOrders() async =>
      order!.waiting ? [] : [order!];
  @override
  Future<DispatchOrder> arrive(String id, int version) async {
    setStage('PILOT_ARRIVED');
    return order!;
  }

  @override
  Future<void> release(String id, int version) async {
    revision++;
    setStage('WAITING_ACCEPTANCE');
  }

  @override
  Future<DispatchOrder> get(String id) async {
    reads++;
    return readGate == null ? order! : readGate!.future;
  }
}
