import 'dispatch_api.dart';
import 'dispatch_requests.dart';
import 'generated/openapi_models.dart';
import 'generated/openapi_paths.dart';
import 'http_client.dart';

class DispatchChatApi {
  DispatchChatApi(this.client);
  final HttpClient client;
  Future<int> open(String orderId, int version) async {
    final raw = await dispatchRequest(
      () => client.dio.post(
        ApiPaths.dispatchOrdersChatPath(orderId),
        data: ApiDispatchAssignmentDTO(assignmentVersion: version).toJson(),
      ),
    );
    final result = ApiDispatchChatVO.fromJson(raw as Map<String, dynamic>);
    if ((result.sessionId ?? 0) <= 0 ||
        result.orderId != orderId ||
        result.assignmentVersion != version) {
      throw const DispatchApiException('聊天会话与当前接单不一致，请刷新订单');
    }
    return result.sessionId!;
  }
}
