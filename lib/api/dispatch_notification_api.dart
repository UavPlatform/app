import 'dispatch_requests.dart';
import 'dispatch_api.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class DispatchNotificationApi {
  DispatchNotificationApi(this.client);
  final HttpClient client;
  Future<int> unread() async {
    final count = await dispatchRequest(
      () => client.dio.get(ApiPaths.dispatchNotificationsUnreadCount),
    );
    if (count is! int || count < 0) {
      throw const DispatchApiException('未读数返回无效，请重试');
    }
    return count;
  }

  Future<ApiDispatchNotificationPageVO> list(int page) async {
    final raw = await dispatchRequest(
      () => client.dio.get(
        ApiPaths.dispatchNotifications,
        queryParameters: ApiPaths.dispatchNotificationsQuery(
          page: page.toString(),
        ),
      ),
    );
    final result = ApiDispatchNotificationPageVO.fromJson(
      raw as Map<String, dynamic>,
    );
    if (result.page != page ||
        result.items == null ||
        result.hasNext == null ||
        (result.unreadCount ?? -1) < 0) {
      throw const DispatchApiException('通知列表返回不完整，请重试');
    }
    for (final item in result.items!) {
      if ((item.notificationId ?? '').isEmpty ||
          (item.orderId ?? '').isEmpty ||
          !const ['OWNER', 'PILOT', 'PILOT_OFFER'].contains(item.audience) ||
          item.createdAt == null) {
        throw const DispatchApiException('通知信息不完整，请重试');
      }
    }
    return result;
  }

  Future<void> read(String id) async {
    await dispatchRequest(
      () => client.dio.post(ApiPaths.dispatchNotificationsReadPath(id)),
      allowEmpty: true,
    );
  }
}
