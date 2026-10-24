import 'package:uav_pilot_app/api/dispatch_notification_api.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';

ApiDispatchNotificationVO notice(
  String id, {
  String order = 'order1',
  String audience = 'OWNER',
}) => ApiDispatchNotificationVO(
  notificationId: id,
  orderId: order,
  audience: audience,
  kind: 'ARRIVED',
  title: '飞手已到场',
  body: '现场核对',
  createdAt: '2026-10-22T12:00:00',
);

class FakeNotificationApi extends DispatchNotificationApi {
  FakeNotificationApi(super.client);
  List<ApiDispatchNotificationVO> items = [notice('n1')];
  int unreadCount = 7;
  Object? failure;
  final reads = <String>[];
  int listCalls = 0;
  @override
  Future<int> unread() async => unreadCount;
  @override
  Future<ApiDispatchNotificationPageVO> list(int page) async {
    listCalls++;
    if (failure != null) throw failure!;
    return ApiDispatchNotificationPageVO(
      items: items,
      page: page,
      hasNext: page == 0,
      unreadCount: unreadCount,
    );
  }

  @override
  Future<void> read(String id) async {
    if (failure != null) throw failure!;
    reads.add(id);
    unreadCount--;
  }
}
