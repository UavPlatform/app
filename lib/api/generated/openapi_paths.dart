// GENERATED — DO NOT EDIT.
// 契约路径表：调用点只允许通过本表拼 URL。
// 生成命令：dart run tool/openapi_gen.dart
// 事实源：openapi/drone-backend.openapi.json (sha256: 649c3f3e02243ba7e828cd225e84f117f18a498515312774f75bd0f66376f7da)
// ignore_for_file: type=lint, unused_element, unused_field, prefer_final_fields

/// 后端端点路径与查询参数的契约映射：路径写错、必填查询参数漏传都会在编译期暴露。
class ApiPaths {
  ApiPaths._();

  static const String generatedFromSha256 = '649c3f3e02243ba7e828cd225e84f117f18a498515312774f75bd0f66376f7da';

  /// GET /task/init
  static const String taskInit = '/task/init';

  /// POST /task/create
  static const String taskCreate = '/task/create';

  /// GET /task/list
  static const String taskList = '/task/list';
  static Map<String, dynamic> taskListQuery({int? page, int? size}) =>
      <String, dynamic>{'page': page, 'size': size};

  /// GET /task/detail
  static const String taskDetail = '/task/detail';
  static Map<String, dynamic> taskDetailQuery({required String taskNum}) =>
      <String, dynamic>{'taskNum': taskNum};

  /// DELETE /task/delete
  static const String taskDelete = '/task/delete';
  static Map<String, dynamic> taskDeleteQuery({required int id}) =>
      <String, dynamic>{'id': id};

  /// POST /task/confirm
  static const String taskConfirm = '/task/confirm';
  static Map<String, dynamic> taskConfirmQuery({required String taskNum}) =>
      <String, dynamic>{'taskNum': taskNum};

  /// GET /chat/session/list
  static const String chatSessionList = '/chat/session/list';

  /// POST /chat/session/create
  static const String chatSessionCreate = '/chat/session/create';

  /// GET /chat/Message/messages/{sessionId}
  static const String chatMessageMessages = '/chat/Message/messages/{sessionId}';
  static String chatMessageMessagesPath(int sessionId) => '/chat/Message/messages/' + sessionId.toString();

  /// POST /chat/Message/send
  static const String chatMessageSend = '/chat/Message/send';

  /// GET /chat/Message/unread/count
  static const String chatMessageUnreadCount = '/chat/Message/unread/count';

  /// POST /chat/Message/read
  static const String chatMessageRead = '/chat/Message/read';
  static Map<String, dynamic> chatMessageReadQuery({required int sessionId}) =>
      <String, dynamic>{'sessionId': sessionId};

  /// GET /rider/square
  static const String riderSquare = '/rider/square';

  /// GET /rider/recommended
  static const String riderRecommended = '/rider/recommended';

  /// GET /rider/my-tasks
  static const String riderMyTasks = '/rider/my-tasks';

  /// GET /rider/my-tasks/history
  static const String riderMyTasksHistory = '/rider/my-tasks/history';

  /// POST /rider/accept
  static const String riderAccept = '/rider/accept';
  static Map<String, dynamic> riderAcceptQuery({required String taskNum}) =>
      <String, dynamic>{'taskNum': taskNum};

  /// POST /rider/cancel
  static const String riderCancel = '/rider/cancel';
  static Map<String, dynamic> riderCancelQuery({required String taskNum}) =>
      <String, dynamic>{'taskNum': taskNum};

  /// POST /rider/complete
  static const String riderComplete = '/rider/complete';
  static Map<String, dynamic> riderCompleteQuery({required String taskNum, String? note}) =>
      <String, dynamic>{'taskNum': taskNum, 'note': note};

  /// POST /rider/register
  static const String riderRegister = '/rider/register';

  /// GET /rider/stats
  static const String riderStats = '/rider/stats';

  /// GET /rider/drone/list
  static const String riderDroneList = '/rider/drone/list';

  /// POST /rider/drone/bind
  static const String riderDroneBind = '/rider/drone/bind';
  static Map<String, dynamic> riderDroneBindQuery({required String djiId}) =>
      <String, dynamic>{'djiId': djiId};

  /// DELETE /rider/drone/unbind
  static const String riderDroneUnbind = '/rider/drone/unbind';
  static Map<String, dynamic> riderDroneUnbindQuery({required String djiId}) =>
      <String, dynamic>{'djiId': djiId};

  /// POST /user/login
  static const String userLogin = '/user/login';

  /// POST /user/register
  static const String userRegister = '/user/register';

  /// POST /user/refresh
  static const String userRefresh = '/user/refresh';

  /// POST /live/get
  static const String liveGet = '/live/get';
  static Map<String, dynamic> liveGetQuery({required String deviceId}) =>
      <String, dynamic>{'deviceId': deviceId};

  /// POST /live/leave
  static const String liveLeave = '/live/leave';
  static Map<String, dynamic> liveLeaveQuery({required String deviceId}) =>
      <String, dynamic>{'deviceId': deviceId};

  /// GET /order/list
  static const String orderList = '/order/list';
  static Map<String, dynamic> orderListQuery({int? page, int? size}) =>
      <String, dynamic>{'page': page, 'size': size};

  /// GET /order/detail
  static const String orderDetail = '/order/detail';
  static Map<String, dynamic> orderDetailQuery({required String orderNum}) =>
      <String, dynamic>{'orderNum': orderNum};

  /// POST /pay/{orderNum}
  static const String pay = '/pay/{orderNum}';
  static String payPath(String orderNum) => '/pay/' + Uri.encodeComponent(orderNum);
  static Map<String, dynamic> payQuery({String? openid}) =>
      <String, dynamic>{'openid': openid};

  /// GET /tasks/{taskNum}/attachments
  static const String tasksAttachments = '/tasks/{taskNum}/attachments';
  static String tasksAttachmentsPath(String taskNum) => '/tasks/' + Uri.encodeComponent(taskNum) + '/attachments';

  /// POST /tasks/{taskNum}/attachments/upload-url
  static const String tasksAttachmentsUploadUrl = '/tasks/{taskNum}/attachments/upload-url';
  static String tasksAttachmentsUploadUrlPath(String taskNum) => '/tasks/' + Uri.encodeComponent(taskNum) + '/attachments/upload-url';
  static Map<String, dynamic> tasksAttachmentsUploadUrlQuery({required String contentType, required String fileName, required int sizeBytes}) =>
      <String, dynamic>{'contentType': contentType, 'fileName': fileName, 'sizeBytes': sizeBytes};
}
