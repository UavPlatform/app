// GENERATED — DO NOT EDIT.
// 契约路径表：调用点只允许通过本表拼 URL。
// 生成命令：dart run tool/openapi_gen.dart
// 事实源：openapi/drone-backend.openapi.json (sha256: fefef9267c01b64dcfc041bc556a3b4c4ce269de597cb561ef257cc3a892afa9)
// ignore_for_file: type=lint, unused_element, unused_field, prefer_final_fields

/// 后端端点路径与查询参数的契约映射：路径写错、必填查询参数漏传都会在编译期暴露。
class ApiPaths {
  ApiPaths._();

  static const String generatedFromSha256 = 'fefef9267c01b64dcfc041bc556a3b4c4ce269de597cb561ef257cc3a892afa9';

  /// GET /dispatch/events
  static const String dispatchEvents = '/dispatch/events';

  /// POST /dispatch/pilot/position-session
  static const String dispatchPilotPositionSession = '/dispatch/pilot/position-session';

  /// PUT /dispatch/pilot/position
  static const String dispatchPilotPosition = '/dispatch/pilot/position';

  /// DELETE /dispatch/pilot/position
  static const String deleteDispatchPilotPosition = '/dispatch/pilot/position';
  static Map<String, dynamic> deleteDispatchPilotPositionQuery({String? sessionKey}) =>
      <String, dynamic>{'sessionKey': sessionKey};

  /// GET /dispatch/pilot/nearby-hall
  static const String dispatchPilotNearbyHall = '/dispatch/pilot/nearby-hall';
  static Map<String, dynamic> dispatchPilotNearbyHallQuery({int? page}) =>
      <String, dynamic>{'page': page};

  /// GET /dispatch/orders/{orderId}/nearby-dispatch
  static const String dispatchOrdersNearbyDispatch = '/dispatch/orders/{orderId}/nearby-dispatch';
  static String dispatchOrdersNearbyDispatchPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/nearby-dispatch';

  /// POST /dispatch/orders/{orderId}/chat
  static const String dispatchOrdersChat = '/dispatch/orders/{orderId}/chat';
  static String dispatchOrdersChatPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/chat';

  /// GET /dispatch/orders/{orderId}/live
  static const String dispatchOrdersLive = '/dispatch/orders/{orderId}/live';
  static String dispatchOrdersLivePath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/live';

  /// POST /dispatch/orders/{orderId}/live/{liveId}/watch
  static const String dispatchOrdersLiveWatch = '/dispatch/orders/{orderId}/live/{liveId}/watch';
  static String dispatchOrdersLiveWatchPath(String liveId, String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/live/' + Uri.encodeComponent(liveId) + '/watch';

  /// GET /dispatch/orders/{orderId}/flight
  static const String dispatchOrdersFlight = '/dispatch/orders/{orderId}/flight';
  static String dispatchOrdersFlightPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/flight';

  /// GET /dispatch/orders/{orderId}/flight/track
  static const String dispatchOrdersFlightTrack = '/dispatch/orders/{orderId}/flight/track';
  static String dispatchOrdersFlightTrackPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/flight/track';
  static Map<String, dynamic> dispatchOrdersFlightTrackQuery({int? after}) =>
      <String, dynamic>{'after': after};

  /// GET /equipment/pilot/drones
  static const String equipmentPilotDrones = '/equipment/pilot/drones';
  static Map<String, dynamic> equipmentPilotDronesQuery({String? page}) =>
      <String, dynamic>{'page': page};

  /// GET /equipment/pilot/borrows
  static const String equipmentPilotBorrows = '/equipment/pilot/borrows';
  static Map<String, dynamic> equipmentPilotBorrowsQuery({String? page}) =>
      <String, dynamic>{'page': page};

  /// POST /equipment/pilot/borrows
  static const String postEquipmentPilotBorrows = '/equipment/pilot/borrows';

  /// POST /equipment/pilot/borrows/{borrowId}/return
  static const String equipmentPilotBorrowsReturn = '/equipment/pilot/borrows/{borrowId}/return';
  static String equipmentPilotBorrowsReturnPath(String borrowId) => '/equipment/pilot/borrows/' + Uri.encodeComponent(borrowId) + '/return';

  /// GET /dispatch/notifications
  static const String dispatchNotifications = '/dispatch/notifications';
  static Map<String, dynamic> dispatchNotificationsQuery({String? page}) =>
      <String, dynamic>{'page': page};

  /// GET /dispatch/notifications/unread-count
  static const String dispatchNotificationsUnreadCount = '/dispatch/notifications/unread-count';

  /// POST /dispatch/notifications/{notificationId}/read
  static const String dispatchNotificationsRead = '/dispatch/notifications/{notificationId}/read';
  static String dispatchNotificationsReadPath(String notificationId) => '/dispatch/notifications/' + Uri.encodeComponent(notificationId) + '/read';

  /// GET /dispatch/config
  static const String dispatchConfig = '/dispatch/config';

  /// GET /dispatch/waybill-draft
  static const String dispatchWaybillDraft = '/dispatch/waybill-draft';

  /// PUT /dispatch/waybill-draft
  static const String putDispatchWaybillDraft = '/dispatch/waybill-draft';

  /// GET /dispatch/readiness
  static const String dispatchReadiness = '/dispatch/readiness';

  /// POST /dispatch/assessments
  static const String dispatchAssessments = '/dispatch/assessments';

  /// GET /dispatch/orders
  static const String dispatchOrders = '/dispatch/orders';

  /// POST /dispatch/orders
  static const String postDispatchOrders = '/dispatch/orders';

  /// GET /dispatch/orders/{orderId}
  static const String getDispatchOrders = '/dispatch/orders/{orderId}';
  static String getDispatchOrdersPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId);

  /// POST /dispatch/orders/{orderId}/simulate-payment
  static const String dispatchOrdersSimulatePayment = '/dispatch/orders/{orderId}/simulate-payment';
  static String dispatchOrdersSimulatePaymentPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/simulate-payment';

  /// POST /dispatch/orders/{orderId}/cancel
  static const String dispatchOrdersCancel = '/dispatch/orders/{orderId}/cancel';
  static String dispatchOrdersCancelPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/cancel';

  /// GET /dispatch/pilot/hall
  static const String dispatchPilotHall = '/dispatch/pilot/hall';
  static Map<String, dynamic> dispatchPilotHallQuery({int? page}) =>
      <String, dynamic>{'page': page};

  /// GET /dispatch/pilot/orders
  static const String dispatchPilotOrders = '/dispatch/pilot/orders';

  /// GET /dispatch/pilot/orders/{orderId}
  static const String getDispatchPilotOrders = '/dispatch/pilot/orders/{orderId}';
  static String getDispatchPilotOrdersPath(String orderId) => '/dispatch/pilot/orders/' + Uri.encodeComponent(orderId);

  /// POST /dispatch/pilot/orders/{orderId}/claim
  static const String dispatchPilotOrdersClaim = '/dispatch/pilot/orders/{orderId}/claim';
  static String dispatchPilotOrdersClaimPath(String orderId) => '/dispatch/pilot/orders/' + Uri.encodeComponent(orderId) + '/claim';

  /// POST /dispatch/pilot/orders/{orderId}/arrive
  static const String dispatchPilotOrdersArrive = '/dispatch/pilot/orders/{orderId}/arrive';
  static String dispatchPilotOrdersArrivePath(String orderId) => '/dispatch/pilot/orders/' + Uri.encodeComponent(orderId) + '/arrive';

  /// POST /dispatch/pilot/orders/{orderId}/release
  static const String dispatchPilotOrdersRelease = '/dispatch/pilot/orders/{orderId}/release';
  static String dispatchPilotOrdersReleasePath(String orderId) => '/dispatch/pilot/orders/' + Uri.encodeComponent(orderId) + '/release';

  /// POST /dispatch/orders/{orderId}/start-transport
  static const String dispatchOrdersStartTransport = '/dispatch/orders/{orderId}/start-transport';
  static String dispatchOrdersStartTransportPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/start-transport';

  /// POST /dispatch/orders/{orderId}/deliver
  static const String dispatchOrdersDeliver = '/dispatch/orders/{orderId}/deliver';
  static String dispatchOrdersDeliverPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/deliver';

  /// POST /dispatch/orders/{orderId}/receipt
  static const String dispatchOrdersReceipt = '/dispatch/orders/{orderId}/receipt';
  static String dispatchOrdersReceiptPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/receipt';

  /// POST /dispatch/orders/{orderId}/settle
  static const String dispatchOrdersSettle = '/dispatch/orders/{orderId}/settle';
  static String dispatchOrdersSettlePath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/settle';

  /// POST /dispatch/orders/{orderId}/review
  static const String dispatchOrdersReview = '/dispatch/orders/{orderId}/review';
  static String dispatchOrdersReviewPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/review';

  /// GET /dispatch/orders/{orderId}/materials
  static const String dispatchOrdersMaterials = '/dispatch/orders/{orderId}/materials';
  static String dispatchOrdersMaterialsPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/materials';

  /// POST /dispatch/orders/{orderId}/materials/upload-ticket
  static const String dispatchOrdersMaterialsUploadTicket = '/dispatch/orders/{orderId}/materials/upload-ticket';
  static String dispatchOrdersMaterialsUploadTicketPath(String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/materials/upload-ticket';

  /// POST /dispatch/orders/{orderId}/materials/{materialId}/confirm
  static const String dispatchOrdersMaterialsConfirm = '/dispatch/orders/{orderId}/materials/{materialId}/confirm';
  static String dispatchOrdersMaterialsConfirmPath(String materialId, String orderId) => '/dispatch/orders/' + Uri.encodeComponent(orderId) + '/materials/' + Uri.encodeComponent(materialId) + '/confirm';

  /// GET /config/map
  static const String configMap = '/config/map';

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

  /// POST /task/{taskNum}/select-rider
  static const String taskSelectRider = '/task/{taskNum}/select-rider';
  static String taskSelectRiderPath(String taskNum) => '/task/' + Uri.encodeComponent(taskNum) + '/select-rider';

  /// GET /task/{taskNum}/applications
  static const String taskApplications = '/task/{taskNum}/applications';
  static String taskApplicationsPath(String taskNum) => '/task/' + Uri.encodeComponent(taskNum) + '/applications';

  /// GET /task/{taskNum}/chat-sessions
  static const String taskChatSessions = '/task/{taskNum}/chat-sessions';
  static String taskChatSessionsPath(String taskNum) => '/task/' + Uri.encodeComponent(taskNum) + '/chat-sessions';

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

  /// GET /rider/task/detail
  static const String riderTaskDetail = '/rider/task/detail';
  static Map<String, dynamic> riderTaskDetailQuery({required String taskNum}) =>
      <String, dynamic>{'taskNum': taskNum};

  /// POST /rider/apply
  static const String riderApply = '/rider/apply';
  static Map<String, dynamic> riderApplyQuery({required dynamic taskNum, required dynamic aircraftModelId}) =>
      <String, dynamic>{'taskNum': taskNum, 'aircraftModelId': aircraftModelId};

  /// POST /rider/confirm-order
  static const String riderConfirmOrder = '/rider/confirm-order';
  static Map<String, dynamic> riderConfirmOrderQuery({required String taskNum}) =>
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
  static Map<String, dynamic> riderDroneBindQuery({required int aircraftModelId, required String djiId}) =>
      <String, dynamic>{'aircraftModelId': aircraftModelId, 'djiId': djiId};

  /// DELETE /rider/drone/unbind
  static const String riderDroneUnbind = '/rider/drone/unbind';
  static Map<String, dynamic> riderDroneUnbindQuery({int? aircraftModelId, required String djiId}) =>
      <String, dynamic>{'aircraftModelId': aircraftModelId, 'djiId': djiId};

  /// GET /api/aircraft-models
  static const String apiAircraftModels = '/api/aircraft-models';

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
  static Map<String, dynamic> orderListQuery({int? size, String? status, int? page}) =>
      <String, dynamic>{'size': size, 'status': status, 'page': page};

  /// GET /order/detail
  static const String orderDetail = '/order/detail';
  static Map<String, dynamic> orderDetailQuery({required String orderNum}) =>
      <String, dynamic>{'orderNum': orderNum};

  /// GET /order/stats
  static const String orderStats = '/order/stats';

  /// GET /order/sold
  static const String orderSold = '/order/sold';
  static Map<String, dynamic> orderSoldQuery({int? size, String? status, int? page}) =>
      <String, dynamic>{'size': size, 'status': status, 'page': page};

  /// GET /order/pending-review
  static const String orderPendingReview = '/order/pending-review';
  static Map<String, dynamic> orderPendingReviewQuery({int? size, int? page}) =>
      <String, dynamic>{'size': size, 'page': page};

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

  /// POST /tasks/{taskNum}/attachments/confirm-upload
  static const String tasksAttachmentsConfirmUpload = '/tasks/{taskNum}/attachments/confirm-upload';
  static String tasksAttachmentsConfirmUploadPath(String taskNum) => '/tasks/' + Uri.encodeComponent(taskNum) + '/attachments/confirm-upload';
  static Map<String, dynamic> tasksAttachmentsConfirmUploadQuery({required String objectKey}) =>
      <String, dynamic>{'objectKey': objectKey};

  /// POST /review/submit
  static const String reviewSubmit = '/review/submit';
  static Map<String, dynamic> reviewSubmitQuery({String? content, required String orderNum, required int rating}) =>
      <String, dynamic>{'content': content, 'orderNum': orderNum, 'rating': rating};

  /// GET /review/{orderNum}
  static const String review = '/review/{orderNum}';
  static String reviewPath(String orderNum) => '/review/' + Uri.encodeComponent(orderNum);

  /// GET /review/my
  static const String reviewMy = '/review/my';
  static Map<String, dynamic> reviewMyQuery({int? page, int? size}) =>
      <String, dynamic>{'page': page, 'size': size};

  /// GET /rider/info
  static const String riderInfo = '/rider/info';

  /// PATCH /rider/info
  static const String patchRiderInfo = '/rider/info';
}
