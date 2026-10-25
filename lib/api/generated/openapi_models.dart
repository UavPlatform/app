// GENERATED — DO NOT EDIT.
// 契约模型：后端 components.schemas 的 Dart 映射。
// 生成命令：dart run tool/openapi_gen.dart
// 事实源：openapi/drone-backend.openapi.json (sha256: c953c4d5b6b6adc327436a587f5cf2ba12d255ee7ca99a9c1ee40bfcb5f27a24)
// ignore_for_file: type=lint, unused_element, unused_field, prefer_final_fields

/// 后端统一返回体 Result<T> 的契约映射。
///
/// 可空性取自契约的 required 列表：springdoc 不把基本类型标为 required，
/// 因此除显式 required 外一律可空（业务侧的默认值收敛在各自模型适配器里）。
class ApiResult<T> {
  const ApiResult({this.success, this.code, this.errorCode, this.message, this.data});

  final bool? success;
  final int? code;
  final String? errorCode;
  final String? message;
  final T? data;

  factory ApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parseData,
  ) {
    final dynamic raw = json["data"];
    return ApiResult<T>(
      success: json["success"] as bool?,
      code: (json["code"] as num?)?.toInt(),
      errorCode: json["errorCode"] as String?,
      message: json["message"] as String?,
      data: raw == null ? null : parseData(raw as Map<String, dynamic>),
    );
  }
}

/// 契约 components.schemas.AircraftModelVO
class ApiAircraftModelVO {
  final double? coefficient;
  final String? displayName;
  final int? id;
  final double? maxPayloadKg;
  final String? modelCode;
  final bool? transportEnabled;

  const ApiAircraftModelVO({this.coefficient, this.displayName, this.id, this.maxPayloadKg, this.modelCode, this.transportEnabled});

  factory ApiAircraftModelVO.fromJson(Map<String, dynamic> json) => ApiAircraftModelVO(
    coefficient: (json['coefficient'] as num?)?.toDouble(),
    displayName: json['displayName'] as String?,
    id: (json['id'] as num?)?.toInt(),
    maxPayloadKg: (json['maxPayloadKg'] as num?)?.toDouble(),
    modelCode: json['modelCode'] as String?,
    transportEnabled: json['transportEnabled'] as bool?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (coefficient != null) {
      json['coefficient'] = coefficient;
    }
    if (displayName != null) {
      json['displayName'] = displayName;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (maxPayloadKg != null) {
      json['maxPayloadKg'] = maxPayloadKg;
    }
    if (modelCode != null) {
      json['modelCode'] = modelCode;
    }
    if (transportEnabled != null) {
      json['transportEnabled'] = transportEnabled;
    }
    return json;
  }
}

/// 契约 components.schemas.AmapConfigVO
class ApiAmapConfigVO {
  final String? key;
  final String? securityKey;

  const ApiAmapConfigVO({this.key, this.securityKey});

  factory ApiAmapConfigVO.fromJson(Map<String, dynamic> json) => ApiAmapConfigVO(
    key: json['key'] as String?,
    securityKey: json['securityKey'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (key != null) {
      json['key'] = key;
    }
    if (securityKey != null) {
      json['securityKey'] = securityKey;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchAssignmentDTO
class ApiDispatchAssignmentDTO {
  final int assignmentVersion;

  const ApiDispatchAssignmentDTO({required this.assignmentVersion});

  factory ApiDispatchAssignmentDTO.fromJson(Map<String, dynamic> json) => ApiDispatchAssignmentDTO(
    assignmentVersion: ((json['assignmentVersion'] as num?)?.toInt() ?? 0),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['assignmentVersion'] = assignmentVersion;
    return json;
  }
}

/// 契约 components.schemas.DispatchBillVO
class ApiDispatchBillVO {
  final double? balanceAmount;
  final double? finalAmount;
  final ApiDispatchQuoteVO? quote;
  final String? reviewComment;
  final int? reviewScore;
  final String? settledAt;
  final String? settlementReference;

  const ApiDispatchBillVO({this.balanceAmount, this.finalAmount, this.quote, this.reviewComment, this.reviewScore, this.settledAt, this.settlementReference});

  factory ApiDispatchBillVO.fromJson(Map<String, dynamic> json) => ApiDispatchBillVO(
    balanceAmount: (json['balanceAmount'] as num?)?.toDouble(),
    finalAmount: (json['finalAmount'] as num?)?.toDouble(),
    quote: (json['quote'] == null ? null : ApiDispatchQuoteVO.fromJson(json['quote'] as Map<String, dynamic>)),
    reviewComment: json['reviewComment'] as String?,
    reviewScore: (json['reviewScore'] as num?)?.toInt(),
    settledAt: json['settledAt'] as String?,
    settlementReference: json['settlementReference'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (balanceAmount != null) {
      json['balanceAmount'] = balanceAmount;
    }
    if (finalAmount != null) {
      json['finalAmount'] = finalAmount;
    }
    if (quote != null) {
      json['quote'] = quote?.toJson();
    }
    if (reviewComment != null) {
      json['reviewComment'] = reviewComment;
    }
    if (reviewScore != null) {
      json['reviewScore'] = reviewScore;
    }
    if (settledAt != null) {
      json['settledAt'] = settledAt;
    }
    if (settlementReference != null) {
      json['settlementReference'] = settlementReference;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchChatVO
class ApiDispatchChatVO {
  final int? assignmentVersion;
  final String? orderId;
  final int? sessionId;

  const ApiDispatchChatVO({this.assignmentVersion, this.orderId, this.sessionId});

  factory ApiDispatchChatVO.fromJson(Map<String, dynamic> json) => ApiDispatchChatVO(
    assignmentVersion: (json['assignmentVersion'] as num?)?.toInt(),
    orderId: json['orderId'] as String?,
    sessionId: (json['sessionId'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (assignmentVersion != null) {
      json['assignmentVersion'] = assignmentVersion;
    }
    if (orderId != null) {
      json['orderId'] = orderId;
    }
    if (sessionId != null) {
      json['sessionId'] = sessionId;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchClaimDTO
class ApiDispatchClaimDTO {
  final int offerRevision;

  const ApiDispatchClaimDTO({required this.offerRevision});

  factory ApiDispatchClaimDTO.fromJson(Map<String, dynamic> json) => ApiDispatchClaimDTO(
    offerRevision: ((json['offerRevision'] as num?)?.toInt() ?? 0),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['offerRevision'] = offerRevision;
    return json;
  }
}

/// 契约 components.schemas.DispatchConfigVO
class ApiDispatchConfigVO {
  final String? currency;
  final double? depositAmount;
  final bool? orderingEnabled;
  final double? pilotServiceFee;

  const ApiDispatchConfigVO({this.currency, this.depositAmount, this.orderingEnabled, this.pilotServiceFee});

  factory ApiDispatchConfigVO.fromJson(Map<String, dynamic> json) => ApiDispatchConfigVO(
    currency: json['currency'] as String?,
    depositAmount: (json['depositAmount'] as num?)?.toDouble(),
    orderingEnabled: json['orderingEnabled'] as bool?,
    pilotServiceFee: (json['pilotServiceFee'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (currency != null) {
      json['currency'] = currency;
    }
    if (depositAmount != null) {
      json['depositAmount'] = depositAmount;
    }
    if (orderingEnabled != null) {
      json['orderingEnabled'] = orderingEnabled;
    }
    if (pilotServiceFee != null) {
      json['pilotServiceFee'] = pilotServiceFee;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchDeliveryDTO
class ApiDispatchDeliveryDTO {
  final int assignmentVersion;
  final List<String> materialIds;

  const ApiDispatchDeliveryDTO({required this.assignmentVersion, required this.materialIds});

  factory ApiDispatchDeliveryDTO.fromJson(Map<String, dynamic> json) => ApiDispatchDeliveryDTO(
    assignmentVersion: ((json['assignmentVersion'] as num?)?.toInt() ?? 0),
    materialIds: ((json['materialIds'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ?? <String>[]),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['assignmentVersion'] = assignmentVersion;
    json['materialIds'] = materialIds;
    return json;
  }
}

/// 契约 components.schemas.DispatchEvaluationVO
class ApiDispatchEvaluationVO {
  final String? airspace;
  final double? altitudeDifferenceMeters;
  final double? distanceMeters;
  final double? flightMinutes;
  final String? source;
  final String? terrain;
  final List<String>? warnings;

  const ApiDispatchEvaluationVO({this.airspace, this.altitudeDifferenceMeters, this.distanceMeters, this.flightMinutes, this.source, this.terrain, this.warnings});

  factory ApiDispatchEvaluationVO.fromJson(Map<String, dynamic> json) => ApiDispatchEvaluationVO(
    airspace: json['airspace'] as String?,
    altitudeDifferenceMeters: (json['altitudeDifferenceMeters'] as num?)?.toDouble(),
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    flightMinutes: (json['flightMinutes'] as num?)?.toDouble(),
    source: json['source'] as String?,
    terrain: json['terrain'] as String?,
    warnings: (json['warnings'] as List<dynamic>?)?.map((dynamic e) => e as String).toList(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (airspace != null) {
      json['airspace'] = airspace;
    }
    if (altitudeDifferenceMeters != null) {
      json['altitudeDifferenceMeters'] = altitudeDifferenceMeters;
    }
    if (distanceMeters != null) {
      json['distanceMeters'] = distanceMeters;
    }
    if (flightMinutes != null) {
      json['flightMinutes'] = flightMinutes;
    }
    if (source != null) {
      json['source'] = source;
    }
    if (terrain != null) {
      json['terrain'] = terrain;
    }
    if (warnings != null) {
      json['warnings'] = warnings;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchExecutedDroneVO
class ApiDispatchExecutedDroneVO {
  final int? aircraftModelId;
  final String? modelCode;
  final String? modelName;
  final String? serialNumber;

  const ApiDispatchExecutedDroneVO({this.aircraftModelId, this.modelCode, this.modelName, this.serialNumber});

  factory ApiDispatchExecutedDroneVO.fromJson(Map<String, dynamic> json) => ApiDispatchExecutedDroneVO(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    modelCode: json['modelCode'] as String?,
    modelName: json['modelName'] as String?,
    serialNumber: json['serialNumber'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (modelCode != null) {
      json['modelCode'] = modelCode;
    }
    if (modelName != null) {
      json['modelName'] = modelName;
    }
    if (serialNumber != null) {
      json['serialNumber'] = serialNumber;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchHallVO
class ApiDispatchHallVO {
  final bool? hasNext;
  final List<ApiDispatchOfferVO>? items;
  final int? page;

  const ApiDispatchHallVO({this.hasNext, this.items, this.page});

  factory ApiDispatchHallVO.fromJson(Map<String, dynamic> json) => ApiDispatchHallVO(
    hasNext: json['hasNext'] as bool?,
    items: (json['items'] as List<dynamic>?)?.map((dynamic e) => ApiDispatchOfferVO.fromJson(e as Map<String, dynamic>)).toList(),
    page: (json['page'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (hasNext != null) {
      json['hasNext'] = hasNext;
    }
    if (items != null) {
      json['items'] = items;
    }
    if (page != null) {
      json['page'] = page;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchLiveCredentialsVO
class ApiDispatchLiveCredentialsVO {
  final String? connectionId;
  final int? expiresAt;
  final int? leaseExpiresAt;
  final String? liveId;
  final String? privateMapKey;
  final String? publisherUserId;
  final String? roomId;
  final int? sdkAppId;
  final String? userId;
  final String? userSig;

  const ApiDispatchLiveCredentialsVO({this.connectionId, this.expiresAt, this.leaseExpiresAt, this.liveId, this.privateMapKey, this.publisherUserId, this.roomId, this.sdkAppId, this.userId, this.userSig});

  factory ApiDispatchLiveCredentialsVO.fromJson(Map<String, dynamic> json) => ApiDispatchLiveCredentialsVO(
    connectionId: json['connectionId'] as String?,
    expiresAt: (json['expiresAt'] as num?)?.toInt(),
    leaseExpiresAt: (json['leaseExpiresAt'] as num?)?.toInt(),
    liveId: json['liveId'] as String?,
    privateMapKey: json['privateMapKey'] as String?,
    publisherUserId: json['publisherUserId'] as String?,
    roomId: json['roomId'] as String?,
    sdkAppId: (json['sdkAppId'] as num?)?.toInt(),
    userId: json['userId'] as String?,
    userSig: json['userSig'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (connectionId != null) {
      json['connectionId'] = connectionId;
    }
    if (expiresAt != null) {
      json['expiresAt'] = expiresAt;
    }
    if (leaseExpiresAt != null) {
      json['leaseExpiresAt'] = leaseExpiresAt;
    }
    if (liveId != null) {
      json['liveId'] = liveId;
    }
    if (privateMapKey != null) {
      json['privateMapKey'] = privateMapKey;
    }
    if (publisherUserId != null) {
      json['publisherUserId'] = publisherUserId;
    }
    if (roomId != null) {
      json['roomId'] = roomId;
    }
    if (sdkAppId != null) {
      json['sdkAppId'] = sdkAppId;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    if (userSig != null) {
      json['userSig'] = userSig;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchLiveStatusVO
class ApiDispatchLiveStatusVO {
  final bool? configured;
  final String? connectionId;
  final int? leaseExpiresAt;
  final String? liveId;
  final String? state;

  const ApiDispatchLiveStatusVO({this.configured, this.connectionId, this.leaseExpiresAt, this.liveId, this.state});

  factory ApiDispatchLiveStatusVO.fromJson(Map<String, dynamic> json) => ApiDispatchLiveStatusVO(
    configured: json['configured'] as bool?,
    connectionId: json['connectionId'] as String?,
    leaseExpiresAt: (json['leaseExpiresAt'] as num?)?.toInt(),
    liveId: json['liveId'] as String?,
    state: json['state'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (configured != null) {
      json['configured'] = configured;
    }
    if (connectionId != null) {
      json['connectionId'] = connectionId;
    }
    if (leaseExpiresAt != null) {
      json['leaseExpiresAt'] = leaseExpiresAt;
    }
    if (liveId != null) {
      json['liveId'] = liveId;
    }
    if (state != null) {
      json['state'] = state;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchMaterialUploadDTO
class ApiDispatchMaterialUploadDTO {
  final String contentType;
  final String fileName;
  final String purpose;
  final int sizeBytes;

  const ApiDispatchMaterialUploadDTO({required this.contentType, required this.fileName, required this.purpose, required this.sizeBytes});

  factory ApiDispatchMaterialUploadDTO.fromJson(Map<String, dynamic> json) => ApiDispatchMaterialUploadDTO(
    contentType: ((json['contentType'] as String?) ?? ""),
    fileName: ((json['fileName'] as String?) ?? ""),
    purpose: ((json['purpose'] as String?) ?? ""),
    sizeBytes: ((json['sizeBytes'] as num?)?.toInt() ?? 0),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['contentType'] = contentType;
    json['fileName'] = fileName;
    json['purpose'] = purpose;
    json['sizeBytes'] = sizeBytes;
    return json;
  }
}

/// 契约 components.schemas.DispatchMaterialVO
class ApiDispatchMaterialVO {
  final String? confirmedAt;
  final String? contentType;
  final String? downloadUrl;
  final String? fileName;
  final String? materialId;
  final String? purpose;
  final int? sizeBytes;
  final String? uploadStatus;
  final int? uploaderId;

  const ApiDispatchMaterialVO({this.confirmedAt, this.contentType, this.downloadUrl, this.fileName, this.materialId, this.purpose, this.sizeBytes, this.uploadStatus, this.uploaderId});

  factory ApiDispatchMaterialVO.fromJson(Map<String, dynamic> json) => ApiDispatchMaterialVO(
    confirmedAt: json['confirmedAt'] as String?,
    contentType: json['contentType'] as String?,
    downloadUrl: json['downloadUrl'] as String?,
    fileName: json['fileName'] as String?,
    materialId: json['materialId'] as String?,
    purpose: json['purpose'] as String?,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    uploadStatus: json['uploadStatus'] as String?,
    uploaderId: (json['uploaderId'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (confirmedAt != null) {
      json['confirmedAt'] = confirmedAt;
    }
    if (contentType != null) {
      json['contentType'] = contentType;
    }
    if (downloadUrl != null) {
      json['downloadUrl'] = downloadUrl;
    }
    if (fileName != null) {
      json['fileName'] = fileName;
    }
    if (materialId != null) {
      json['materialId'] = materialId;
    }
    if (purpose != null) {
      json['purpose'] = purpose;
    }
    if (sizeBytes != null) {
      json['sizeBytes'] = sizeBytes;
    }
    if (uploadStatus != null) {
      json['uploadStatus'] = uploadStatus;
    }
    if (uploaderId != null) {
      json['uploaderId'] = uploaderId;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchNearbyHallVO
class ApiDispatchNearbyHallVO {
  final bool? hasNext;
  final List<ApiDispatchNearbyOfferVO>? items;
  final int? locationExpiresAt;
  final String? locationState;
  final int? page;
  final double? radiusKm;

  const ApiDispatchNearbyHallVO({this.hasNext, this.items, this.locationExpiresAt, this.locationState, this.page, this.radiusKm});

  factory ApiDispatchNearbyHallVO.fromJson(Map<String, dynamic> json) => ApiDispatchNearbyHallVO(
    hasNext: json['hasNext'] as bool?,
    items: (json['items'] as List<dynamic>?)?.map((dynamic e) => ApiDispatchNearbyOfferVO.fromJson(e as Map<String, dynamic>)).toList(),
    locationExpiresAt: (json['locationExpiresAt'] as num?)?.toInt(),
    locationState: json['locationState'] as String?,
    page: (json['page'] as num?)?.toInt(),
    radiusKm: (json['radiusKm'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (hasNext != null) {
      json['hasNext'] = hasNext;
    }
    if (items != null) {
      json['items'] = items;
    }
    if (locationExpiresAt != null) {
      json['locationExpiresAt'] = locationExpiresAt;
    }
    if (locationState != null) {
      json['locationState'] = locationState;
    }
    if (page != null) {
      json['page'] = page;
    }
    if (radiusKm != null) {
      json['radiusKm'] = radiusKm;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchNearbyOfferVO
class ApiDispatchNearbyOfferVO {
  final double? distanceMeters;
  final ApiDispatchOfferVO? offer;

  const ApiDispatchNearbyOfferVO({this.distanceMeters, this.offer});

  factory ApiDispatchNearbyOfferVO.fromJson(Map<String, dynamic> json) => ApiDispatchNearbyOfferVO(
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    offer: (json['offer'] == null ? null : ApiDispatchOfferVO.fromJson(json['offer'] as Map<String, dynamic>)),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (distanceMeters != null) {
      json['distanceMeters'] = distanceMeters;
    }
    if (offer != null) {
      json['offer'] = offer?.toJson();
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchNearbyStatusVO
class ApiDispatchNearbyStatusVO {
  final int? assignmentVersion;
  final int? notifiedPilotCount;
  final String? orderId;
  final double? radiusKm;
  final String? reminderAt;
  final bool? reminderSent;
  final String? state;
  final bool? systemPushEnabled;
  final String? waitingSince;

  const ApiDispatchNearbyStatusVO({this.assignmentVersion, this.notifiedPilotCount, this.orderId, this.radiusKm, this.reminderAt, this.reminderSent, this.state, this.systemPushEnabled, this.waitingSince});

  factory ApiDispatchNearbyStatusVO.fromJson(Map<String, dynamic> json) => ApiDispatchNearbyStatusVO(
    assignmentVersion: (json['assignmentVersion'] as num?)?.toInt(),
    notifiedPilotCount: (json['notifiedPilotCount'] as num?)?.toInt(),
    orderId: json['orderId'] as String?,
    radiusKm: (json['radiusKm'] as num?)?.toDouble(),
    reminderAt: json['reminderAt'] as String?,
    reminderSent: json['reminderSent'] as bool?,
    state: json['state'] as String?,
    systemPushEnabled: json['systemPushEnabled'] as bool?,
    waitingSince: json['waitingSince'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (assignmentVersion != null) {
      json['assignmentVersion'] = assignmentVersion;
    }
    if (notifiedPilotCount != null) {
      json['notifiedPilotCount'] = notifiedPilotCount;
    }
    if (orderId != null) {
      json['orderId'] = orderId;
    }
    if (radiusKm != null) {
      json['radiusKm'] = radiusKm;
    }
    if (reminderAt != null) {
      json['reminderAt'] = reminderAt;
    }
    if (reminderSent != null) {
      json['reminderSent'] = reminderSent;
    }
    if (state != null) {
      json['state'] = state;
    }
    if (systemPushEnabled != null) {
      json['systemPushEnabled'] = systemPushEnabled;
    }
    if (waitingSince != null) {
      json['waitingSince'] = waitingSince;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchNotificationPageVO
class ApiDispatchNotificationPageVO {
  final bool? hasNext;
  final List<ApiDispatchNotificationVO>? items;
  final int? page;
  final int? unreadCount;

  const ApiDispatchNotificationPageVO({this.hasNext, this.items, this.page, this.unreadCount});

  factory ApiDispatchNotificationPageVO.fromJson(Map<String, dynamic> json) => ApiDispatchNotificationPageVO(
    hasNext: json['hasNext'] as bool?,
    items: (json['items'] as List<dynamic>?)?.map((dynamic e) => ApiDispatchNotificationVO.fromJson(e as Map<String, dynamic>)).toList(),
    page: (json['page'] as num?)?.toInt(),
    unreadCount: (json['unreadCount'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (hasNext != null) {
      json['hasNext'] = hasNext;
    }
    if (items != null) {
      json['items'] = items;
    }
    if (page != null) {
      json['page'] = page;
    }
    if (unreadCount != null) {
      json['unreadCount'] = unreadCount;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchNotificationVO
class ApiDispatchNotificationVO {
  final String? audience;
  final String? body;
  final String? createdAt;
  final String? kind;
  final String? notificationId;
  final String? orderId;
  final String? readAt;
  final String? title;

  const ApiDispatchNotificationVO({this.audience, this.body, this.createdAt, this.kind, this.notificationId, this.orderId, this.readAt, this.title});

  factory ApiDispatchNotificationVO.fromJson(Map<String, dynamic> json) => ApiDispatchNotificationVO(
    audience: json['audience'] as String?,
    body: json['body'] as String?,
    createdAt: json['createdAt'] as String?,
    kind: json['kind'] as String?,
    notificationId: json['notificationId'] as String?,
    orderId: json['orderId'] as String?,
    readAt: json['readAt'] as String?,
    title: json['title'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (audience != null) {
      json['audience'] = audience;
    }
    if (body != null) {
      json['body'] = body;
    }
    if (createdAt != null) {
      json['createdAt'] = createdAt;
    }
    if (kind != null) {
      json['kind'] = kind;
    }
    if (notificationId != null) {
      json['notificationId'] = notificationId;
    }
    if (orderId != null) {
      json['orderId'] = orderId;
    }
    if (readAt != null) {
      json['readAt'] = readAt;
    }
    if (title != null) {
      json['title'] = title;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchOfferVO
class ApiDispatchOfferVO {
  final String? createdAt;
  final Map<String, dynamic>? fields;
  final int? offerRevision;
  final String? orderId;
  final double? pilotServiceFee;

  const ApiDispatchOfferVO({this.createdAt, this.fields, this.offerRevision, this.orderId, this.pilotServiceFee});

  factory ApiDispatchOfferVO.fromJson(Map<String, dynamic> json) => ApiDispatchOfferVO(
    createdAt: json['createdAt'] as String?,
    fields: json['fields'] as Map<String, dynamic>?,
    offerRevision: (json['offerRevision'] as num?)?.toInt(),
    orderId: json['orderId'] as String?,
    pilotServiceFee: (json['pilotServiceFee'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (createdAt != null) {
      json['createdAt'] = createdAt;
    }
    if (fields != null) {
      json['fields'] = fields;
    }
    if (offerRevision != null) {
      json['offerRevision'] = offerRevision;
    }
    if (orderId != null) {
      json['orderId'] = orderId;
    }
    if (pilotServiceFee != null) {
      json['pilotServiceFee'] = pilotServiceFee;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchOrderDTO
class ApiDispatchOrderDTO {
  final String assessmentId;
  final bool declarationAccepted;
  final String requestKey;
  final ApiWaybillDraftDTO waybill;

  const ApiDispatchOrderDTO({required this.assessmentId, required this.declarationAccepted, required this.requestKey, required this.waybill});

  factory ApiDispatchOrderDTO.fromJson(Map<String, dynamic> json) => ApiDispatchOrderDTO(
    assessmentId: ((json['assessmentId'] as String?) ?? ""),
    declarationAccepted: ((json['declarationAccepted'] as bool?) ?? false),
    requestKey: ((json['requestKey'] as String?) ?? ""),
    waybill: ApiWaybillDraftDTO.fromJson(json['waybill'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['assessmentId'] = assessmentId;
    json['declarationAccepted'] = declarationAccepted;
    json['requestKey'] = requestKey;
    json['waybill'] = waybill.toJson();
    return json;
  }
}

/// 契约 components.schemas.DispatchOrderVO
class ApiDispatchOrderVO {
  final int? assignedPilotId;
  final int? assignmentVersion;
  final ApiDispatchBillVO? bill;
  final String? createdAt;
  final String? currency;
  final String? deliveredAt;
  final double? depositAmount;
  final ApiDispatchExecutedDroneVO? executedDrone;
  final Map<String, dynamic>? fields;
  final String? fundsStatus;
  final String? orderId;
  final String? paymentMode;
  final String? paymentReference;
  final double? pilotServiceFee;
  final String? receiptAt;
  final String? refundReference;
  final String? stage;
  final String? startedAt;
  final String? updatedAt;

  const ApiDispatchOrderVO({this.assignedPilotId, this.assignmentVersion, this.bill, this.createdAt, this.currency, this.deliveredAt, this.depositAmount, this.executedDrone, this.fields, this.fundsStatus, this.orderId, this.paymentMode, this.paymentReference, this.pilotServiceFee, this.receiptAt, this.refundReference, this.stage, this.startedAt, this.updatedAt});

  factory ApiDispatchOrderVO.fromJson(Map<String, dynamic> json) => ApiDispatchOrderVO(
    assignedPilotId: (json['assignedPilotId'] as num?)?.toInt(),
    assignmentVersion: (json['assignmentVersion'] as num?)?.toInt(),
    bill: (json['bill'] == null ? null : ApiDispatchBillVO.fromJson(json['bill'] as Map<String, dynamic>)),
    createdAt: json['createdAt'] as String?,
    currency: json['currency'] as String?,
    deliveredAt: json['deliveredAt'] as String?,
    depositAmount: (json['depositAmount'] as num?)?.toDouble(),
    executedDrone: (json['executedDrone'] == null ? null : ApiDispatchExecutedDroneVO.fromJson(json['executedDrone'] as Map<String, dynamic>)),
    fields: json['fields'] as Map<String, dynamic>?,
    fundsStatus: json['fundsStatus'] as String?,
    orderId: json['orderId'] as String?,
    paymentMode: json['paymentMode'] as String?,
    paymentReference: json['paymentReference'] as String?,
    pilotServiceFee: (json['pilotServiceFee'] as num?)?.toDouble(),
    receiptAt: json['receiptAt'] as String?,
    refundReference: json['refundReference'] as String?,
    stage: json['stage'] as String?,
    startedAt: json['startedAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (assignedPilotId != null) {
      json['assignedPilotId'] = assignedPilotId;
    }
    if (assignmentVersion != null) {
      json['assignmentVersion'] = assignmentVersion;
    }
    if (bill != null) {
      json['bill'] = bill?.toJson();
    }
    if (createdAt != null) {
      json['createdAt'] = createdAt;
    }
    if (currency != null) {
      json['currency'] = currency;
    }
    if (deliveredAt != null) {
      json['deliveredAt'] = deliveredAt;
    }
    if (depositAmount != null) {
      json['depositAmount'] = depositAmount;
    }
    if (executedDrone != null) {
      json['executedDrone'] = executedDrone?.toJson();
    }
    if (fields != null) {
      json['fields'] = fields;
    }
    if (fundsStatus != null) {
      json['fundsStatus'] = fundsStatus;
    }
    if (orderId != null) {
      json['orderId'] = orderId;
    }
    if (paymentMode != null) {
      json['paymentMode'] = paymentMode;
    }
    if (paymentReference != null) {
      json['paymentReference'] = paymentReference;
    }
    if (pilotServiceFee != null) {
      json['pilotServiceFee'] = pilotServiceFee;
    }
    if (receiptAt != null) {
      json['receiptAt'] = receiptAt;
    }
    if (refundReference != null) {
      json['refundReference'] = refundReference;
    }
    if (stage != null) {
      json['stage'] = stage;
    }
    if (startedAt != null) {
      json['startedAt'] = startedAt;
    }
    if (updatedAt != null) {
      json['updatedAt'] = updatedAt;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchPositionDTO
class ApiDispatchPositionDTO {
  final double accuracyMeters;
  final int capturedAt;
  final String coordinateSystem;
  final double latitude;
  final double longitude;
  final bool mocked;
  final String sessionKey;

  const ApiDispatchPositionDTO({required this.accuracyMeters, required this.capturedAt, required this.coordinateSystem, required this.latitude, required this.longitude, required this.mocked, required this.sessionKey});

  factory ApiDispatchPositionDTO.fromJson(Map<String, dynamic> json) => ApiDispatchPositionDTO(
    accuracyMeters: ((json['accuracyMeters'] as num?)?.toDouble() ?? 0),
    capturedAt: ((json['capturedAt'] as num?)?.toInt() ?? 0),
    coordinateSystem: ((json['coordinateSystem'] as String?) ?? ""),
    latitude: ((json['latitude'] as num?)?.toDouble() ?? 0),
    longitude: ((json['longitude'] as num?)?.toDouble() ?? 0),
    mocked: ((json['mocked'] as bool?) ?? false),
    sessionKey: ((json['sessionKey'] as String?) ?? ""),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['accuracyMeters'] = accuracyMeters;
    json['capturedAt'] = capturedAt;
    json['coordinateSystem'] = coordinateSystem;
    json['latitude'] = latitude;
    json['longitude'] = longitude;
    json['mocked'] = mocked;
    json['sessionKey'] = sessionKey;
    return json;
  }
}

/// 契约 components.schemas.DispatchPositionVO
class ApiDispatchPositionVO {
  final double? accuracyMeters;
  final String? coordinateSystem;
  final int? expiresAt;
  final int? receivedAt;

  const ApiDispatchPositionVO({this.accuracyMeters, this.coordinateSystem, this.expiresAt, this.receivedAt});

  factory ApiDispatchPositionVO.fromJson(Map<String, dynamic> json) => ApiDispatchPositionVO(
    accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
    coordinateSystem: json['coordinateSystem'] as String?,
    expiresAt: (json['expiresAt'] as num?)?.toInt(),
    receivedAt: (json['receivedAt'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (accuracyMeters != null) {
      json['accuracyMeters'] = accuracyMeters;
    }
    if (coordinateSystem != null) {
      json['coordinateSystem'] = coordinateSystem;
    }
    if (expiresAt != null) {
      json['expiresAt'] = expiresAt;
    }
    if (receivedAt != null) {
      json['receivedAt'] = receivedAt;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchQuoteVO
class ApiDispatchQuoteVO {
  final double? depositAmount;
  final String? distanceBasis;
  final double? distanceCharge;
  final double? distanceMeters;
  final double? pilotServiceFee;
  final double? pricePerMeter;
  final String? rule;
  final double? totalAmount;

  const ApiDispatchQuoteVO({this.depositAmount, this.distanceBasis, this.distanceCharge, this.distanceMeters, this.pilotServiceFee, this.pricePerMeter, this.rule, this.totalAmount});

  factory ApiDispatchQuoteVO.fromJson(Map<String, dynamic> json) => ApiDispatchQuoteVO(
    depositAmount: (json['depositAmount'] as num?)?.toDouble(),
    distanceBasis: json['distanceBasis'] as String?,
    distanceCharge: (json['distanceCharge'] as num?)?.toDouble(),
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    pilotServiceFee: (json['pilotServiceFee'] as num?)?.toDouble(),
    pricePerMeter: (json['pricePerMeter'] as num?)?.toDouble(),
    rule: json['rule'] as String?,
    totalAmount: (json['totalAmount'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (depositAmount != null) {
      json['depositAmount'] = depositAmount;
    }
    if (distanceBasis != null) {
      json['distanceBasis'] = distanceBasis;
    }
    if (distanceCharge != null) {
      json['distanceCharge'] = distanceCharge;
    }
    if (distanceMeters != null) {
      json['distanceMeters'] = distanceMeters;
    }
    if (pilotServiceFee != null) {
      json['pilotServiceFee'] = pilotServiceFee;
    }
    if (pricePerMeter != null) {
      json['pricePerMeter'] = pricePerMeter;
    }
    if (rule != null) {
      json['rule'] = rule;
    }
    if (totalAmount != null) {
      json['totalAmount'] = totalAmount;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchReadinessVO
class ApiDispatchReadinessVO {
  final List<String>? blockers;
  final bool? orderingEnabled;
  final String? paymentMode;

  const ApiDispatchReadinessVO({this.blockers, this.orderingEnabled, this.paymentMode});

  factory ApiDispatchReadinessVO.fromJson(Map<String, dynamic> json) => ApiDispatchReadinessVO(
    blockers: (json['blockers'] as List<dynamic>?)?.map((dynamic e) => e as String).toList(),
    orderingEnabled: json['orderingEnabled'] as bool?,
    paymentMode: json['paymentMode'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (blockers != null) {
      json['blockers'] = blockers;
    }
    if (orderingEnabled != null) {
      json['orderingEnabled'] = orderingEnabled;
    }
    if (paymentMode != null) {
      json['paymentMode'] = paymentMode;
    }
    return json;
  }
}

/// 契约 components.schemas.DispatchReceiptDTO
class ApiDispatchReceiptDTO {
  final List<String> materialIds;

  const ApiDispatchReceiptDTO({required this.materialIds});

  factory ApiDispatchReceiptDTO.fromJson(Map<String, dynamic> json) => ApiDispatchReceiptDTO(
    materialIds: ((json['materialIds'] as List<dynamic>?)?.map((dynamic e) => e as String).toList() ?? <String>[]),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['materialIds'] = materialIds;
    return json;
  }
}

/// 契约 components.schemas.DispatchReviewDTO
class ApiDispatchReviewDTO {
  final String? comment;
  final int score;

  const ApiDispatchReviewDTO({this.comment, required this.score});

  factory ApiDispatchReviewDTO.fromJson(Map<String, dynamic> json) => ApiDispatchReviewDTO(
    comment: json['comment'] as String?,
    score: ((json['score'] as num?)?.toInt() ?? 0),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (comment != null) {
      json['comment'] = comment;
    }
    json['score'] = score;
    return json;
  }
}

/// 契约 components.schemas.DispatchUploadTicketVO
class ApiDispatchUploadTicketVO {
  final String? contentType;
  final int? expireSeconds;
  final String? materialId;
  final String? method;
  final int? sizeBytes;
  final String? uploadUrl;

  const ApiDispatchUploadTicketVO({this.contentType, this.expireSeconds, this.materialId, this.method, this.sizeBytes, this.uploadUrl});

  factory ApiDispatchUploadTicketVO.fromJson(Map<String, dynamic> json) => ApiDispatchUploadTicketVO(
    contentType: json['contentType'] as String?,
    expireSeconds: (json['expireSeconds'] as num?)?.toInt(),
    materialId: json['materialId'] as String?,
    method: json['method'] as String?,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    uploadUrl: json['uploadUrl'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (contentType != null) {
      json['contentType'] = contentType;
    }
    if (expireSeconds != null) {
      json['expireSeconds'] = expireSeconds;
    }
    if (materialId != null) {
      json['materialId'] = materialId;
    }
    if (method != null) {
      json['method'] = method;
    }
    if (sizeBytes != null) {
      json['sizeBytes'] = sizeBytes;
    }
    if (uploadUrl != null) {
      json['uploadUrl'] = uploadUrl;
    }
    return json;
  }
}

/// 契约 components.schemas.DroneBorrowDTO
class ApiDroneBorrowDTO {
  final String droneId;
  final String requestKey;

  const ApiDroneBorrowDTO({required this.droneId, required this.requestKey});

  factory ApiDroneBorrowDTO.fromJson(Map<String, dynamic> json) => ApiDroneBorrowDTO(
    droneId: ((json['droneId'] as String?) ?? ""),
    requestKey: ((json['requestKey'] as String?) ?? ""),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['droneId'] = droneId;
    json['requestKey'] = requestKey;
    return json;
  }
}

/// 契约 components.schemas.DroneBorrowPageVO
class ApiDroneBorrowPageVO {
  final bool? hasNext;
  final List<ApiDroneBorrowVO>? items;
  final int? page;

  const ApiDroneBorrowPageVO({this.hasNext, this.items, this.page});

  factory ApiDroneBorrowPageVO.fromJson(Map<String, dynamic> json) => ApiDroneBorrowPageVO(
    hasNext: json['hasNext'] as bool?,
    items: (json['items'] as List<dynamic>?)?.map((dynamic e) => ApiDroneBorrowVO.fromJson(e as Map<String, dynamic>)).toList(),
    page: (json['page'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (hasNext != null) {
      json['hasNext'] = hasNext;
    }
    if (items != null) {
      json['items'] = items;
    }
    if (page != null) {
      json['page'] = page;
    }
    return json;
  }
}

/// 契约 components.schemas.DroneBorrowVO
class ApiDroneBorrowVO {
  final String? borrowId;
  final String? borrowedAt;
  final ApiProviderDroneVO? drone;
  final int? pilotId;
  final String? returnedAt;

  const ApiDroneBorrowVO({this.borrowId, this.borrowedAt, this.drone, this.pilotId, this.returnedAt});

  factory ApiDroneBorrowVO.fromJson(Map<String, dynamic> json) => ApiDroneBorrowVO(
    borrowId: json['borrowId'] as String?,
    borrowedAt: json['borrowedAt'] as String?,
    drone: (json['drone'] == null ? null : ApiProviderDroneVO.fromJson(json['drone'] as Map<String, dynamic>)),
    pilotId: (json['pilotId'] as num?)?.toInt(),
    returnedAt: json['returnedAt'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (borrowId != null) {
      json['borrowId'] = borrowId;
    }
    if (borrowedAt != null) {
      json['borrowedAt'] = borrowedAt;
    }
    if (drone != null) {
      json['drone'] = drone?.toJson();
    }
    if (pilotId != null) {
      json['pilotId'] = pilotId;
    }
    if (returnedAt != null) {
      json['returnedAt'] = returnedAt;
    }
    return json;
  }
}

/// 契约 components.schemas.FlightConnectionVO
class ApiFlightConnectionVO {
  final int? aircraftModelId;
  final int? assignmentVersion;
  final String? connectionId;
  final String? endReason;
  final String? endedAt;
  final double? maxPayloadKg;
  final String? modelCode;
  final String? modelName;
  final String? openedAt;
  final String? orderId;
  final bool? overweight;
  final String? serialNumber;

  const ApiFlightConnectionVO({this.aircraftModelId, this.assignmentVersion, this.connectionId, this.endReason, this.endedAt, this.maxPayloadKg, this.modelCode, this.modelName, this.openedAt, this.orderId, this.overweight, this.serialNumber});

  factory ApiFlightConnectionVO.fromJson(Map<String, dynamic> json) => ApiFlightConnectionVO(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    assignmentVersion: (json['assignmentVersion'] as num?)?.toInt(),
    connectionId: json['connectionId'] as String?,
    endReason: json['endReason'] as String?,
    endedAt: json['endedAt'] as String?,
    maxPayloadKg: (json['maxPayloadKg'] as num?)?.toDouble(),
    modelCode: json['modelCode'] as String?,
    modelName: json['modelName'] as String?,
    openedAt: json['openedAt'] as String?,
    orderId: json['orderId'] as String?,
    overweight: json['overweight'] as bool?,
    serialNumber: json['serialNumber'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (assignmentVersion != null) {
      json['assignmentVersion'] = assignmentVersion;
    }
    if (connectionId != null) {
      json['connectionId'] = connectionId;
    }
    if (endReason != null) {
      json['endReason'] = endReason;
    }
    if (endedAt != null) {
      json['endedAt'] = endedAt;
    }
    if (maxPayloadKg != null) {
      json['maxPayloadKg'] = maxPayloadKg;
    }
    if (modelCode != null) {
      json['modelCode'] = modelCode;
    }
    if (modelName != null) {
      json['modelName'] = modelName;
    }
    if (openedAt != null) {
      json['openedAt'] = openedAt;
    }
    if (orderId != null) {
      json['orderId'] = orderId;
    }
    if (overweight != null) {
      json['overweight'] = overweight;
    }
    if (serialNumber != null) {
      json['serialNumber'] = serialNumber;
    }
    return json;
  }
}

/// 契约 components.schemas.FlightSampleVO
class ApiFlightSampleVO {
  final double? altitude;
  final int? battery;
  final int? capturedAt;
  final String? connectionId;
  final bool? flying;
  final double? latitude;
  final double? longitude;
  final double? payloadKg;
  final String? receivedAt;
  final int? sampleId;
  final int? sequence;
  final double? speed;

  const ApiFlightSampleVO({this.altitude, this.battery, this.capturedAt, this.connectionId, this.flying, this.latitude, this.longitude, this.payloadKg, this.receivedAt, this.sampleId, this.sequence, this.speed});

  factory ApiFlightSampleVO.fromJson(Map<String, dynamic> json) => ApiFlightSampleVO(
    altitude: (json['altitude'] as num?)?.toDouble(),
    battery: (json['battery'] as num?)?.toInt(),
    capturedAt: (json['capturedAt'] as num?)?.toInt(),
    connectionId: json['connectionId'] as String?,
    flying: json['flying'] as bool?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    payloadKg: (json['payloadKg'] as num?)?.toDouble(),
    receivedAt: json['receivedAt'] as String?,
    sampleId: (json['sampleId'] as num?)?.toInt(),
    sequence: (json['sequence'] as num?)?.toInt(),
    speed: (json['speed'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (altitude != null) {
      json['altitude'] = altitude;
    }
    if (battery != null) {
      json['battery'] = battery;
    }
    if (capturedAt != null) {
      json['capturedAt'] = capturedAt;
    }
    if (connectionId != null) {
      json['connectionId'] = connectionId;
    }
    if (flying != null) {
      json['flying'] = flying;
    }
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    if (longitude != null) {
      json['longitude'] = longitude;
    }
    if (payloadKg != null) {
      json['payloadKg'] = payloadKg;
    }
    if (receivedAt != null) {
      json['receivedAt'] = receivedAt;
    }
    if (sampleId != null) {
      json['sampleId'] = sampleId;
    }
    if (sequence != null) {
      json['sequence'] = sequence;
    }
    if (speed != null) {
      json['speed'] = speed;
    }
    return json;
  }
}

/// 契约 components.schemas.FlightTrackVO
class ApiFlightTrackVO {
  final bool? hasNext;
  final List<ApiFlightSampleVO>? items;
  final int? nextAfter;

  const ApiFlightTrackVO({this.hasNext, this.items, this.nextAfter});

  factory ApiFlightTrackVO.fromJson(Map<String, dynamic> json) => ApiFlightTrackVO(
    hasNext: json['hasNext'] as bool?,
    items: (json['items'] as List<dynamic>?)?.map((dynamic e) => ApiFlightSampleVO.fromJson(e as Map<String, dynamic>)).toList(),
    nextAfter: (json['nextAfter'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (hasNext != null) {
      json['hasNext'] = hasNext;
    }
    if (items != null) {
      json['items'] = items;
    }
    if (nextAfter != null) {
      json['nextAfter'] = nextAfter;
    }
    return json;
  }
}

/// 契约 components.schemas.FlightViewVO
class ApiFlightViewVO {
  final ApiFlightConnectionVO? connection;
  final List<ApiFlightConnectionVO>? connectionHistory;
  final ApiFlightSampleVO? lastPosition;
  final ApiFlightSampleVO? latest;
  final bool? stale;

  const ApiFlightViewVO({this.connection, this.connectionHistory, this.lastPosition, this.latest, this.stale});

  factory ApiFlightViewVO.fromJson(Map<String, dynamic> json) => ApiFlightViewVO(
    connection: (json['connection'] == null ? null : ApiFlightConnectionVO.fromJson(json['connection'] as Map<String, dynamic>)),
    connectionHistory: (json['connectionHistory'] as List<dynamic>?)?.map((dynamic e) => ApiFlightConnectionVO.fromJson(e as Map<String, dynamic>)).toList(),
    lastPosition: (json['lastPosition'] == null ? null : ApiFlightSampleVO.fromJson(json['lastPosition'] as Map<String, dynamic>)),
    latest: (json['latest'] == null ? null : ApiFlightSampleVO.fromJson(json['latest'] as Map<String, dynamic>)),
    stale: json['stale'] as bool?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (connection != null) {
      json['connection'] = connection?.toJson();
    }
    if (connectionHistory != null) {
      json['connectionHistory'] = connectionHistory;
    }
    if (lastPosition != null) {
      json['lastPosition'] = lastPosition?.toJson();
    }
    if (latest != null) {
      json['latest'] = latest?.toJson();
    }
    if (stale != null) {
      json['stale'] = stale;
    }
    return json;
  }
}

/// 契约 components.schemas.MessageDTO
class ApiMessageDTO {
  final String content;
  final int? createTime;
  final int? fromUserId;
  final String? msgId;
  final int sessionId;

  const ApiMessageDTO({required this.content, this.createTime, this.fromUserId, this.msgId, required this.sessionId});

  factory ApiMessageDTO.fromJson(Map<String, dynamic> json) => ApiMessageDTO(
    content: ((json['content'] as String?) ?? ""),
    createTime: (json['createTime'] as num?)?.toInt(),
    fromUserId: (json['fromUserId'] as num?)?.toInt(),
    msgId: json['msgId'] as String?,
    sessionId: ((json['sessionId'] as num?)?.toInt() ?? 0),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content;
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (fromUserId != null) {
      json['fromUserId'] = fromUserId;
    }
    if (msgId != null) {
      json['msgId'] = msgId;
    }
    json['sessionId'] = sessionId;
    return json;
  }
}

/// 契约 components.schemas.OrderListVO
class ApiOrderListVO {
  final int? currentPage;
  final List<ApiOrderVO>? orders;
  final int? totalElements;
  final int? totalPages;

  const ApiOrderListVO({this.currentPage, this.orders, this.totalElements, this.totalPages});

  factory ApiOrderListVO.fromJson(Map<String, dynamic> json) => ApiOrderListVO(
    currentPage: (json['currentPage'] as num?)?.toInt(),
    orders: (json['orders'] as List<dynamic>?)?.map((dynamic e) => ApiOrderVO.fromJson(e as Map<String, dynamic>)).toList(),
    totalElements: (json['totalElements'] as num?)?.toInt(),
    totalPages: (json['totalPages'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (currentPage != null) {
      json['currentPage'] = currentPage;
    }
    if (orders != null) {
      json['orders'] = orders;
    }
    if (totalElements != null) {
      json['totalElements'] = totalElements;
    }
    if (totalPages != null) {
      json['totalPages'] = totalPages;
    }
    return json;
  }
}

/// 契约 components.schemas.OrderReview
class ApiOrderReview {
  final String? content;
  final String? createTime;
  final int? id;
  final String? orderNum;
  final int? rating;
  final int? userId;

  const ApiOrderReview({this.content, this.createTime, this.id, this.orderNum, this.rating, this.userId});

  factory ApiOrderReview.fromJson(Map<String, dynamic> json) => ApiOrderReview(
    content: json['content'] as String?,
    createTime: json['createTime'] as String?,
    id: (json['id'] as num?)?.toInt(),
    orderNum: json['orderNum'] as String?,
    rating: (json['rating'] as num?)?.toInt(),
    userId: (json['userId'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (content != null) {
      json['content'] = content;
    }
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (orderNum != null) {
      json['orderNum'] = orderNum;
    }
    if (rating != null) {
      json['rating'] = rating;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    return json;
  }
}

/// 契约 components.schemas.OrderVO
class ApiOrderVO {
  final String? deviceId;
  final double? distance;
  final String? executeResult;
  final String? executedAt;
  final List<ApiUploadVO>? files;
  final bool? hasReview;
  final String? liveState;
  final String? orderNum;
  final int? orderStatus;
  final String? taskName;
  final double? totalAmount;

  const ApiOrderVO({this.deviceId, this.distance, this.executeResult, this.executedAt, this.files, this.hasReview, this.liveState, this.orderNum, this.orderStatus, this.taskName, this.totalAmount});

  factory ApiOrderVO.fromJson(Map<String, dynamic> json) => ApiOrderVO(
    deviceId: json['deviceId'] as String?,
    distance: (json['distance'] as num?)?.toDouble(),
    executeResult: json['executeResult'] as String?,
    executedAt: json['executedAt'] as String?,
    files: (json['files'] as List<dynamic>?)?.map((dynamic e) => ApiUploadVO.fromJson(e as Map<String, dynamic>)).toList(),
    hasReview: json['hasReview'] as bool?,
    liveState: json['liveState'] as String?,
    orderNum: json['orderNum'] as String?,
    orderStatus: (json['orderStatus'] as num?)?.toInt(),
    taskName: json['taskName'] as String?,
    totalAmount: (json['totalAmount'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (deviceId != null) {
      json['deviceId'] = deviceId;
    }
    if (distance != null) {
      json['distance'] = distance;
    }
    if (executeResult != null) {
      json['executeResult'] = executeResult;
    }
    if (executedAt != null) {
      json['executedAt'] = executedAt;
    }
    if (files != null) {
      json['files'] = files;
    }
    if (hasReview != null) {
      json['hasReview'] = hasReview;
    }
    if (liveState != null) {
      json['liveState'] = liveState;
    }
    if (orderNum != null) {
      json['orderNum'] = orderNum;
    }
    if (orderStatus != null) {
      json['orderStatus'] = orderStatus;
    }
    if (taskName != null) {
      json['taskName'] = taskName;
    }
    if (totalAmount != null) {
      json['totalAmount'] = totalAmount;
    }
    return json;
  }
}

/// 契约 components.schemas.PayResultVO
class ApiPayResultVO {
  final String? orderNum;
  final String? payUrl;
  final String? prepayId;

  const ApiPayResultVO({this.orderNum, this.payUrl, this.prepayId});

  factory ApiPayResultVO.fromJson(Map<String, dynamic> json) => ApiPayResultVO(
    orderNum: json['orderNum'] as String?,
    payUrl: json['payUrl'] as String?,
    prepayId: json['prepayId'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (orderNum != null) {
      json['orderNum'] = orderNum;
    }
    if (payUrl != null) {
      json['payUrl'] = payUrl;
    }
    if (prepayId != null) {
      json['prepayId'] = prepayId;
    }
    return json;
  }
}

/// 契约 components.schemas.ProviderDronePageVO
class ApiProviderDronePageVO {
  final bool? hasNext;
  final List<ApiProviderDroneVO>? items;
  final int? page;

  const ApiProviderDronePageVO({this.hasNext, this.items, this.page});

  factory ApiProviderDronePageVO.fromJson(Map<String, dynamic> json) => ApiProviderDronePageVO(
    hasNext: json['hasNext'] as bool?,
    items: (json['items'] as List<dynamic>?)?.map((dynamic e) => ApiProviderDroneVO.fromJson(e as Map<String, dynamic>)).toList(),
    page: (json['page'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (hasNext != null) {
      json['hasNext'] = hasNext;
    }
    if (items != null) {
      json['items'] = items;
    }
    if (page != null) {
      json['page'] = page;
    }
    return json;
  }
}

/// 契约 components.schemas.ProviderDroneVO
class ApiProviderDroneVO {
  final int? aircraftModelId;
  final String? airportName;
  final bool? borrowed;
  final bool? borrowedByMe;
  final String? currentBorrowId;
  final String? droneId;
  final bool? enabled;
  final double? latitude;
  final double? longitude;
  final String? modelName;
  final int? providerId;
  final String? providerName;
  final String? serialNumber;

  const ApiProviderDroneVO({this.aircraftModelId, this.airportName, this.borrowed, this.borrowedByMe, this.currentBorrowId, this.droneId, this.enabled, this.latitude, this.longitude, this.modelName, this.providerId, this.providerName, this.serialNumber});

  factory ApiProviderDroneVO.fromJson(Map<String, dynamic> json) => ApiProviderDroneVO(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    airportName: json['airportName'] as String?,
    borrowed: json['borrowed'] as bool?,
    borrowedByMe: json['borrowedByMe'] as bool?,
    currentBorrowId: json['currentBorrowId'] as String?,
    droneId: json['droneId'] as String?,
    enabled: json['enabled'] as bool?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    modelName: json['modelName'] as String?,
    providerId: (json['providerId'] as num?)?.toInt(),
    providerName: json['providerName'] as String?,
    serialNumber: json['serialNumber'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (airportName != null) {
      json['airportName'] = airportName;
    }
    if (borrowed != null) {
      json['borrowed'] = borrowed;
    }
    if (borrowedByMe != null) {
      json['borrowedByMe'] = borrowedByMe;
    }
    if (currentBorrowId != null) {
      json['currentBorrowId'] = currentBorrowId;
    }
    if (droneId != null) {
      json['droneId'] = droneId;
    }
    if (enabled != null) {
      json['enabled'] = enabled;
    }
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    if (longitude != null) {
      json['longitude'] = longitude;
    }
    if (modelName != null) {
      json['modelName'] = modelName;
    }
    if (providerId != null) {
      json['providerId'] = providerId;
    }
    if (providerName != null) {
      json['providerName'] = providerName;
    }
    if (serialNumber != null) {
      json['serialNumber'] = serialNumber;
    }
    return json;
  }
}

/// 契约 components.schemas.PullCredentialsVO
class ApiPullCredentialsVO {
  final bool? ackConfirmed;
  final String? liveState;
  final String? privateMapKey;
  final String? roomId;
  final int? sdkAppId;
  final String? userId;
  final String? userSig;
  final String? wsUrl;

  const ApiPullCredentialsVO({this.ackConfirmed, this.liveState, this.privateMapKey, this.roomId, this.sdkAppId, this.userId, this.userSig, this.wsUrl});

  factory ApiPullCredentialsVO.fromJson(Map<String, dynamic> json) => ApiPullCredentialsVO(
    ackConfirmed: json['ackConfirmed'] as bool?,
    liveState: json['liveState'] as String?,
    privateMapKey: json['privateMapKey'] as String?,
    roomId: json['roomId'] as String?,
    sdkAppId: (json['sdkAppId'] as num?)?.toInt(),
    userId: json['userId'] as String?,
    userSig: json['userSig'] as String?,
    wsUrl: json['wsUrl'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (ackConfirmed != null) {
      json['ackConfirmed'] = ackConfirmed;
    }
    if (liveState != null) {
      json['liveState'] = liveState;
    }
    if (privateMapKey != null) {
      json['privateMapKey'] = privateMapKey;
    }
    if (roomId != null) {
      json['roomId'] = roomId;
    }
    if (sdkAppId != null) {
      json['sdkAppId'] = sdkAppId;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    if (userSig != null) {
      json['userSig'] = userSig;
    }
    if (wsUrl != null) {
      json['wsUrl'] = wsUrl;
    }
    return json;
  }
}

/// 契约 components.schemas.RegisterVo
class ApiRegisterVo {
  final int? id;
  final String? userName;

  const ApiRegisterVo({this.id, this.userName});

  factory ApiRegisterVo.fromJson(Map<String, dynamic> json) => ApiRegisterVo(
    id: (json['id'] as num?)?.toInt(),
    userName: json['userName'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (id != null) {
      json['id'] = id;
    }
    if (userName != null) {
      json['userName'] = userName;
    }
    return json;
  }
}

/// 契约 components.schemas.ReviewListVO
class ApiReviewListVO {
  final int? currentPage;
  final List<ApiOrderReview>? reviews;
  final int? totalElements;
  final int? totalPages;

  const ApiReviewListVO({this.currentPage, this.reviews, this.totalElements, this.totalPages});

  factory ApiReviewListVO.fromJson(Map<String, dynamic> json) => ApiReviewListVO(
    currentPage: (json['currentPage'] as num?)?.toInt(),
    reviews: (json['reviews'] as List<dynamic>?)?.map((dynamic e) => ApiOrderReview.fromJson(e as Map<String, dynamic>)).toList(),
    totalElements: (json['totalElements'] as num?)?.toInt(),
    totalPages: (json['totalPages'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (currentPage != null) {
      json['currentPage'] = currentPage;
    }
    if (reviews != null) {
      json['reviews'] = reviews;
    }
    if (totalElements != null) {
      json['totalElements'] = totalElements;
    }
    if (totalPages != null) {
      json['totalPages'] = totalPages;
    }
    return json;
  }
}

/// 契约 components.schemas.RiderApplyDto
class ApiRiderApplyDto {
  final int? aircraftModelId;
  final String? taskNum;

  const ApiRiderApplyDto({this.aircraftModelId, this.taskNum});

  factory ApiRiderApplyDto.fromJson(Map<String, dynamic> json) => ApiRiderApplyDto(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    taskNum: json['taskNum'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (taskNum != null) {
      json['taskNum'] = taskNum;
    }
    return json;
  }
}

/// 契约 components.schemas.RiderInfoDto
class ApiRiderInfoDto {
  final int? age;
  final String? idExpiryDate;
  final String? idNumber;
  final String? location;
  final List<ApiRiderQualificationDto>? qualifications;
  final String? selfIntroduction;

  const ApiRiderInfoDto({this.age, this.idExpiryDate, this.idNumber, this.location, this.qualifications, this.selfIntroduction});

  factory ApiRiderInfoDto.fromJson(Map<String, dynamic> json) => ApiRiderInfoDto(
    age: (json['age'] as num?)?.toInt(),
    idExpiryDate: json['idExpiryDate'] as String?,
    idNumber: json['idNumber'] as String?,
    location: json['location'] as String?,
    qualifications: (json['qualifications'] as List<dynamic>?)?.map((dynamic e) => ApiRiderQualificationDto.fromJson(e as Map<String, dynamic>)).toList(),
    selfIntroduction: json['selfIntroduction'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (age != null) {
      json['age'] = age;
    }
    if (idExpiryDate != null) {
      json['idExpiryDate'] = idExpiryDate;
    }
    if (idNumber != null) {
      json['idNumber'] = idNumber;
    }
    if (location != null) {
      json['location'] = location;
    }
    if (qualifications != null) {
      json['qualifications'] = qualifications;
    }
    if (selfIntroduction != null) {
      json['selfIntroduction'] = selfIntroduction;
    }
    return json;
  }
}

/// 契约 components.schemas.RiderInfoVO
class ApiRiderInfoVO {
  final int? age;
  final String? createTime;
  final bool? idExpired;
  final String? idExpiryDate;
  final String? idNumberMasked;
  final String? location;
  final List<ApiRiderQualificationVO>? qualifications;
  final String? selfIntroduction;
  final String? updateTime;
  final int? userId;
  final String? userName;

  const ApiRiderInfoVO({this.age, this.createTime, this.idExpired, this.idExpiryDate, this.idNumberMasked, this.location, this.qualifications, this.selfIntroduction, this.updateTime, this.userId, this.userName});

  factory ApiRiderInfoVO.fromJson(Map<String, dynamic> json) => ApiRiderInfoVO(
    age: (json['age'] as num?)?.toInt(),
    createTime: json['createTime'] as String?,
    idExpired: json['idExpired'] as bool?,
    idExpiryDate: json['idExpiryDate'] as String?,
    idNumberMasked: json['idNumberMasked'] as String?,
    location: json['location'] as String?,
    qualifications: (json['qualifications'] as List<dynamic>?)?.map((dynamic e) => ApiRiderQualificationVO.fromJson(e as Map<String, dynamic>)).toList(),
    selfIntroduction: json['selfIntroduction'] as String?,
    updateTime: json['updateTime'] as String?,
    userId: (json['userId'] as num?)?.toInt(),
    userName: json['userName'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (age != null) {
      json['age'] = age;
    }
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (idExpired != null) {
      json['idExpired'] = idExpired;
    }
    if (idExpiryDate != null) {
      json['idExpiryDate'] = idExpiryDate;
    }
    if (idNumberMasked != null) {
      json['idNumberMasked'] = idNumberMasked;
    }
    if (location != null) {
      json['location'] = location;
    }
    if (qualifications != null) {
      json['qualifications'] = qualifications;
    }
    if (selfIntroduction != null) {
      json['selfIntroduction'] = selfIntroduction;
    }
    if (updateTime != null) {
      json['updateTime'] = updateTime;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    if (userName != null) {
      json['userName'] = userName;
    }
    return json;
  }
}

/// 契约 components.schemas.RiderQualificationDto
class ApiRiderQualificationDto {
  final int aircraftModelId;
  final String licenseGrade;

  const ApiRiderQualificationDto({required this.aircraftModelId, required this.licenseGrade});

  factory ApiRiderQualificationDto.fromJson(Map<String, dynamic> json) => ApiRiderQualificationDto(
    aircraftModelId: ((json['aircraftModelId'] as num?)?.toInt() ?? 0),
    licenseGrade: ((json['licenseGrade'] as String?) ?? ""),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['aircraftModelId'] = aircraftModelId;
    json['licenseGrade'] = licenseGrade;
    return json;
  }
}

/// 契约 components.schemas.RiderQualificationVO
class ApiRiderQualificationVO {
  final int? aircraftModelId;
  final int? id;
  final String? licenseGrade;
  final String? licenseGradeLabel;
  final String? modelCode;
  final String? modelName;

  const ApiRiderQualificationVO({this.aircraftModelId, this.id, this.licenseGrade, this.licenseGradeLabel, this.modelCode, this.modelName});

  factory ApiRiderQualificationVO.fromJson(Map<String, dynamic> json) => ApiRiderQualificationVO(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    id: (json['id'] as num?)?.toInt(),
    licenseGrade: json['licenseGrade'] as String?,
    licenseGradeLabel: json['licenseGradeLabel'] as String?,
    modelCode: json['modelCode'] as String?,
    modelName: json['modelName'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (licenseGrade != null) {
      json['licenseGrade'] = licenseGrade;
    }
    if (licenseGradeLabel != null) {
      json['licenseGradeLabel'] = licenseGradeLabel;
    }
    if (modelCode != null) {
      json['modelCode'] = modelCode;
    }
    if (modelName != null) {
      json['modelName'] = modelName;
    }
    return json;
  }
}

/// 契约 components.schemas.RiderRegisterDto
class ApiRiderRegisterDto {
  final int? aircraftModelId;
  final String? djiId;
  final String? password;
  final String? userName;

  const ApiRiderRegisterDto({this.aircraftModelId, this.djiId, this.password, this.userName});

  factory ApiRiderRegisterDto.fromJson(Map<String, dynamic> json) => ApiRiderRegisterDto(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    djiId: json['djiId'] as String?,
    password: json['password'] as String?,
    userName: json['userName'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (djiId != null) {
      json['djiId'] = djiId;
    }
    if (password != null) {
      json['password'] = password;
    }
    if (userName != null) {
      json['userName'] = userName;
    }
    return json;
  }
}

/// 契约 components.schemas.RiderStatsVO
class ApiRiderStatsVO {
  final int? riderId;
  final String? riderName;
  final int? todayOrders;
  final int? totalCompleted;
  final double? totalEarnings;

  const ApiRiderStatsVO({this.riderId, this.riderName, this.todayOrders, this.totalCompleted, this.totalEarnings});

  factory ApiRiderStatsVO.fromJson(Map<String, dynamic> json) => ApiRiderStatsVO(
    riderId: (json['riderId'] as num?)?.toInt(),
    riderName: json['riderName'] as String?,
    todayOrders: (json['todayOrders'] as num?)?.toInt(),
    totalCompleted: (json['totalCompleted'] as num?)?.toInt(),
    totalEarnings: (json['totalEarnings'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (riderId != null) {
      json['riderId'] = riderId;
    }
    if (riderName != null) {
      json['riderName'] = riderName;
    }
    if (todayOrders != null) {
      json['todayOrders'] = todayOrders;
    }
    if (totalCompleted != null) {
      json['totalCompleted'] = totalCompleted;
    }
    if (totalEarnings != null) {
      json['totalEarnings'] = totalEarnings;
    }
    return json;
  }
}

/// 契约 components.schemas.RiderUav
class ApiRiderUav {
  final int? aircraftModelId;
  final String? createTime;
  final String? djiId;
  final int? id;
  final int? userId;

  const ApiRiderUav({this.aircraftModelId, this.createTime, this.djiId, this.id, this.userId});

  factory ApiRiderUav.fromJson(Map<String, dynamic> json) => ApiRiderUav(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    createTime: json['createTime'] as String?,
    djiId: json['djiId'] as String?,
    id: (json['id'] as num?)?.toInt(),
    userId: (json['userId'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (djiId != null) {
      json['djiId'] = djiId;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    return json;
  }
}

/// 契约 components.schemas.SelectRiderDto
class ApiSelectRiderDto {
  final int applicationId;
  final String scheduledTime;

  const ApiSelectRiderDto({required this.applicationId, required this.scheduledTime});

  factory ApiSelectRiderDto.fromJson(Map<String, dynamic> json) => ApiSelectRiderDto(
    applicationId: ((json['applicationId'] as num?)?.toInt() ?? 0),
    scheduledTime: ((json['scheduledTime'] as String?) ?? ""),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['applicationId'] = applicationId;
    json['scheduledTime'] = scheduledTime;
    return json;
  }
}

/// 契约 components.schemas.SessionDTO
class ApiSessionDTO {
  final int? applicationId;
  final String? avatar;
  final String? description;
  final String name;
  final String? taskNum;
  final int type;
  final List<int> userIds;

  const ApiSessionDTO({this.applicationId, this.avatar, this.description, required this.name, this.taskNum, required this.type, required this.userIds});

  factory ApiSessionDTO.fromJson(Map<String, dynamic> json) => ApiSessionDTO(
    applicationId: (json['applicationId'] as num?)?.toInt(),
    avatar: json['avatar'] as String?,
    description: json['description'] as String?,
    name: ((json['name'] as String?) ?? ""),
    taskNum: json['taskNum'] as String?,
    type: ((json['type'] as num?)?.toInt() ?? 0),
    userIds: ((json['userIds'] as List<dynamic>?)?.map((dynamic e) => (e as num).toInt()).toList() ?? <int>[]),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (applicationId != null) {
      json['applicationId'] = applicationId;
    }
    if (avatar != null) {
      json['avatar'] = avatar;
    }
    if (description != null) {
      json['description'] = description;
    }
    json['name'] = name;
    if (taskNum != null) {
      json['taskNum'] = taskNum;
    }
    json['type'] = type;
    json['userIds'] = userIds;
    return json;
  }
}

/// 契约 components.schemas.SessionVO
class ApiSessionVO {
  final int? applicationId;
  final String? avatar;
  final int? createTime;
  final String? description;
  final int? id;
  final String? lastMessage;
  final int? lastMessageTime;
  final String? name;
  final String? otherUserName;
  final int? ownerId;
  final String? taskNum;
  final int? type;
  final int? unreadCount;
  final List<int>? userIds;

  const ApiSessionVO({this.applicationId, this.avatar, this.createTime, this.description, this.id, this.lastMessage, this.lastMessageTime, this.name, this.otherUserName, this.ownerId, this.taskNum, this.type, this.unreadCount, this.userIds});

  factory ApiSessionVO.fromJson(Map<String, dynamic> json) => ApiSessionVO(
    applicationId: (json['applicationId'] as num?)?.toInt(),
    avatar: json['avatar'] as String?,
    createTime: (json['createTime'] as num?)?.toInt(),
    description: json['description'] as String?,
    id: (json['id'] as num?)?.toInt(),
    lastMessage: json['lastMessage'] as String?,
    lastMessageTime: (json['lastMessageTime'] as num?)?.toInt(),
    name: json['name'] as String?,
    otherUserName: json['otherUserName'] as String?,
    ownerId: (json['ownerId'] as num?)?.toInt(),
    taskNum: json['taskNum'] as String?,
    type: (json['type'] as num?)?.toInt(),
    unreadCount: (json['unreadCount'] as num?)?.toInt(),
    userIds: (json['userIds'] as List<dynamic>?)?.map((dynamic e) => (e as num).toInt()).toList(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (applicationId != null) {
      json['applicationId'] = applicationId;
    }
    if (avatar != null) {
      json['avatar'] = avatar;
    }
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (lastMessage != null) {
      json['lastMessage'] = lastMessage;
    }
    if (lastMessageTime != null) {
      json['lastMessageTime'] = lastMessageTime;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (otherUserName != null) {
      json['otherUserName'] = otherUserName;
    }
    if (ownerId != null) {
      json['ownerId'] = ownerId;
    }
    if (taskNum != null) {
      json['taskNum'] = taskNum;
    }
    if (type != null) {
      json['type'] = type;
    }
    if (unreadCount != null) {
      json['unreadCount'] = unreadCount;
    }
    if (userIds != null) {
      json['userIds'] = userIds;
    }
    return json;
  }
}

/// 契约 components.schemas.SubmitReviewVO
class ApiSubmitReviewVO {
  final String? orderNum;
  final int? rating;

  const ApiSubmitReviewVO({this.orderNum, this.rating});

  factory ApiSubmitReviewVO.fromJson(Map<String, dynamic> json) => ApiSubmitReviewVO(
    orderNum: json['orderNum'] as String?,
    rating: (json['rating'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (orderNum != null) {
      json['orderNum'] = orderNum;
    }
    if (rating != null) {
      json['rating'] = rating;
    }
    return json;
  }
}

/// 契约 components.schemas.TaskApplicationVO
class ApiTaskApplicationVO {
  final int? aircraftModelId;
  final String? aircraftModelName;
  final int? applicationId;
  final String? appliedAt;
  final String? matchStatus;
  final double? maxPayloadKg;
  final String? modelCode;
  final double? quotedAmount;
  final int? riderId;
  final String? riderName;
  final String? status;
  final String? taskNum;

  const ApiTaskApplicationVO({this.aircraftModelId, this.aircraftModelName, this.applicationId, this.appliedAt, this.matchStatus, this.maxPayloadKg, this.modelCode, this.quotedAmount, this.riderId, this.riderName, this.status, this.taskNum});

  factory ApiTaskApplicationVO.fromJson(Map<String, dynamic> json) => ApiTaskApplicationVO(
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    aircraftModelName: json['aircraftModelName'] as String?,
    applicationId: (json['applicationId'] as num?)?.toInt(),
    appliedAt: json['appliedAt'] as String?,
    matchStatus: json['matchStatus'] as String?,
    maxPayloadKg: (json['maxPayloadKg'] as num?)?.toDouble(),
    modelCode: json['modelCode'] as String?,
    quotedAmount: (json['quotedAmount'] as num?)?.toDouble(),
    riderId: (json['riderId'] as num?)?.toInt(),
    riderName: json['riderName'] as String?,
    status: json['status'] as String?,
    taskNum: json['taskNum'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (aircraftModelName != null) {
      json['aircraftModelName'] = aircraftModelName;
    }
    if (applicationId != null) {
      json['applicationId'] = applicationId;
    }
    if (appliedAt != null) {
      json['appliedAt'] = appliedAt;
    }
    if (matchStatus != null) {
      json['matchStatus'] = matchStatus;
    }
    if (maxPayloadKg != null) {
      json['maxPayloadKg'] = maxPayloadKg;
    }
    if (modelCode != null) {
      json['modelCode'] = modelCode;
    }
    if (quotedAmount != null) {
      json['quotedAmount'] = quotedAmount;
    }
    if (riderId != null) {
      json['riderId'] = riderId;
    }
    if (riderName != null) {
      json['riderName'] = riderName;
    }
    if (status != null) {
      json['status'] = status;
    }
    if (taskNum != null) {
      json['taskNum'] = taskNum;
    }
    return json;
  }
}

/// 契约 components.schemas.TaskChatSessionVO
class ApiTaskChatSessionVO {
  final int? applicationId;
  final int? createTime;
  final String? lastMessage;
  final int? lastMessageTime;
  final String? name;
  final int? otherUserId;
  final String? otherUserName;
  final int? ownerId;
  final int? riderId;
  final String? riderName;
  final int? sessionId;
  final String? taskNum;
  final int? type;
  final int? unreadCount;

  const ApiTaskChatSessionVO({this.applicationId, this.createTime, this.lastMessage, this.lastMessageTime, this.name, this.otherUserId, this.otherUserName, this.ownerId, this.riderId, this.riderName, this.sessionId, this.taskNum, this.type, this.unreadCount});

  factory ApiTaskChatSessionVO.fromJson(Map<String, dynamic> json) => ApiTaskChatSessionVO(
    applicationId: (json['applicationId'] as num?)?.toInt(),
    createTime: (json['createTime'] as num?)?.toInt(),
    lastMessage: json['lastMessage'] as String?,
    lastMessageTime: (json['lastMessageTime'] as num?)?.toInt(),
    name: json['name'] as String?,
    otherUserId: (json['otherUserId'] as num?)?.toInt(),
    otherUserName: json['otherUserName'] as String?,
    ownerId: (json['ownerId'] as num?)?.toInt(),
    riderId: (json['riderId'] as num?)?.toInt(),
    riderName: json['riderName'] as String?,
    sessionId: (json['sessionId'] as num?)?.toInt(),
    taskNum: json['taskNum'] as String?,
    type: (json['type'] as num?)?.toInt(),
    unreadCount: (json['unreadCount'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (applicationId != null) {
      json['applicationId'] = applicationId;
    }
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (lastMessage != null) {
      json['lastMessage'] = lastMessage;
    }
    if (lastMessageTime != null) {
      json['lastMessageTime'] = lastMessageTime;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (otherUserId != null) {
      json['otherUserId'] = otherUserId;
    }
    if (otherUserName != null) {
      json['otherUserName'] = otherUserName;
    }
    if (ownerId != null) {
      json['ownerId'] = ownerId;
    }
    if (riderId != null) {
      json['riderId'] = riderId;
    }
    if (riderName != null) {
      json['riderName'] = riderName;
    }
    if (sessionId != null) {
      json['sessionId'] = sessionId;
    }
    if (taskNum != null) {
      json['taskNum'] = taskNum;
    }
    if (type != null) {
      json['type'] = type;
    }
    if (unreadCount != null) {
      json['unreadCount'] = unreadCount;
    }
    return json;
  }
}

/// 契约 components.schemas.TaskDto
class ApiTaskDto {
  final String? cargoCategory;
  final double? cargoWeightKg;
  final String? description;
  final double? reward;
  final String? taskName;
  final String? taskTime;
  final String? type;
  final List<ApiWaypointDto>? waypoints;

  const ApiTaskDto({this.cargoCategory, this.cargoWeightKg, this.description, this.reward, this.taskName, this.taskTime, this.type, this.waypoints});

  factory ApiTaskDto.fromJson(Map<String, dynamic> json) => ApiTaskDto(
    cargoCategory: json['cargoCategory'] as String?,
    cargoWeightKg: (json['cargoWeightKg'] as num?)?.toDouble(),
    description: json['description'] as String?,
    reward: (json['reward'] as num?)?.toDouble(),
    taskName: json['taskName'] as String?,
    taskTime: json['taskTime'] as String?,
    type: json['type'] as String?,
    waypoints: (json['waypoints'] as List<dynamic>?)?.map((dynamic e) => ApiWaypointDto.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (cargoCategory != null) {
      json['cargoCategory'] = cargoCategory;
    }
    if (cargoWeightKg != null) {
      json['cargoWeightKg'] = cargoWeightKg;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (reward != null) {
      json['reward'] = reward;
    }
    if (taskName != null) {
      json['taskName'] = taskName;
    }
    if (taskTime != null) {
      json['taskTime'] = taskTime;
    }
    if (type != null) {
      json['type'] = type;
    }
    if (waypoints != null) {
      json['waypoints'] = waypoints;
    }
    return json;
  }
}

/// 契约 components.schemas.TaskPageVO
class ApiTaskPageVO {
  final int? currentPage;
  final List<ApiTaskVo>? tasks;
  final int? totalElements;
  final int? totalPages;

  const ApiTaskPageVO({this.currentPage, this.tasks, this.totalElements, this.totalPages});

  factory ApiTaskPageVO.fromJson(Map<String, dynamic> json) => ApiTaskPageVO(
    currentPage: (json['currentPage'] as num?)?.toInt(),
    tasks: (json['tasks'] as List<dynamic>?)?.map((dynamic e) => ApiTaskVo.fromJson(e as Map<String, dynamic>)).toList(),
    totalElements: (json['totalElements'] as num?)?.toInt(),
    totalPages: (json['totalPages'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (currentPage != null) {
      json['currentPage'] = currentPage;
    }
    if (tasks != null) {
      json['tasks'] = tasks;
    }
    if (totalElements != null) {
      json['totalElements'] = totalElements;
    }
    if (totalPages != null) {
      json['totalPages'] = totalPages;
    }
    return json;
  }
}

/// 契约 components.schemas.TaskVo
class ApiTaskVo {
  final String? acceptTime;
  final String? actionHint;
  final int? aircraftModelId;
  final String? aircraftModelName;
  final String? cargoCategory;
  final double? cargoWeightKg;
  final String? completeNote;
  final String? createTime;
  final String? description;
  final String? deviceId;
  final int? id;
  final String? liveState;
  final String? matchStatus;
  final String? modelCode;
  final String? orderNum;
  final String? orderStatus;
  final double? quotedAmount;
  final String? riderConfirmedAt;
  final int? riderId;
  final String? riderName;
  final String? scheduledTime;
  final String? taskName;
  final String? taskNum;
  final String? taskStatus;
  final String? taskTime;
  final String? taskType;
  final double? totalAmount;
  final double? totalDistance;
  final String? updateTime;
  final String? userConfirmedAt;
  final int? userId;
  final List<ApiWaypointVo>? waypoints;

  const ApiTaskVo({this.acceptTime, this.actionHint, this.aircraftModelId, this.aircraftModelName, this.cargoCategory, this.cargoWeightKg, this.completeNote, this.createTime, this.description, this.deviceId, this.id, this.liveState, this.matchStatus, this.modelCode, this.orderNum, this.orderStatus, this.quotedAmount, this.riderConfirmedAt, this.riderId, this.riderName, this.scheduledTime, this.taskName, this.taskNum, this.taskStatus, this.taskTime, this.taskType, this.totalAmount, this.totalDistance, this.updateTime, this.userConfirmedAt, this.userId, this.waypoints});

  factory ApiTaskVo.fromJson(Map<String, dynamic> json) => ApiTaskVo(
    acceptTime: json['acceptTime'] as String?,
    actionHint: json['actionHint'] as String?,
    aircraftModelId: (json['aircraftModelId'] as num?)?.toInt(),
    aircraftModelName: json['aircraftModelName'] as String?,
    cargoCategory: json['cargoCategory'] as String?,
    cargoWeightKg: (json['cargoWeightKg'] as num?)?.toDouble(),
    completeNote: json['completeNote'] as String?,
    createTime: json['createTime'] as String?,
    description: json['description'] as String?,
    deviceId: json['deviceId'] as String?,
    id: (json['id'] as num?)?.toInt(),
    liveState: json['liveState'] as String?,
    matchStatus: json['matchStatus'] as String?,
    modelCode: json['modelCode'] as String?,
    orderNum: json['orderNum'] as String?,
    orderStatus: json['orderStatus'] as String?,
    quotedAmount: (json['quotedAmount'] as num?)?.toDouble(),
    riderConfirmedAt: json['riderConfirmedAt'] as String?,
    riderId: (json['riderId'] as num?)?.toInt(),
    riderName: json['riderName'] as String?,
    scheduledTime: json['scheduledTime'] as String?,
    taskName: json['taskName'] as String?,
    taskNum: json['taskNum'] as String?,
    taskStatus: json['taskStatus'] as String?,
    taskTime: json['taskTime'] as String?,
    taskType: json['taskType'] as String?,
    totalAmount: (json['totalAmount'] as num?)?.toDouble(),
    totalDistance: (json['totalDistance'] as num?)?.toDouble(),
    updateTime: json['updateTime'] as String?,
    userConfirmedAt: json['userConfirmedAt'] as String?,
    userId: (json['userId'] as num?)?.toInt(),
    waypoints: (json['waypoints'] as List<dynamic>?)?.map((dynamic e) => ApiWaypointVo.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (acceptTime != null) {
      json['acceptTime'] = acceptTime;
    }
    if (actionHint != null) {
      json['actionHint'] = actionHint;
    }
    if (aircraftModelId != null) {
      json['aircraftModelId'] = aircraftModelId;
    }
    if (aircraftModelName != null) {
      json['aircraftModelName'] = aircraftModelName;
    }
    if (cargoCategory != null) {
      json['cargoCategory'] = cargoCategory;
    }
    if (cargoWeightKg != null) {
      json['cargoWeightKg'] = cargoWeightKg;
    }
    if (completeNote != null) {
      json['completeNote'] = completeNote;
    }
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (deviceId != null) {
      json['deviceId'] = deviceId;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (liveState != null) {
      json['liveState'] = liveState;
    }
    if (matchStatus != null) {
      json['matchStatus'] = matchStatus;
    }
    if (modelCode != null) {
      json['modelCode'] = modelCode;
    }
    if (orderNum != null) {
      json['orderNum'] = orderNum;
    }
    if (orderStatus != null) {
      json['orderStatus'] = orderStatus;
    }
    if (quotedAmount != null) {
      json['quotedAmount'] = quotedAmount;
    }
    if (riderConfirmedAt != null) {
      json['riderConfirmedAt'] = riderConfirmedAt;
    }
    if (riderId != null) {
      json['riderId'] = riderId;
    }
    if (riderName != null) {
      json['riderName'] = riderName;
    }
    if (scheduledTime != null) {
      json['scheduledTime'] = scheduledTime;
    }
    if (taskName != null) {
      json['taskName'] = taskName;
    }
    if (taskNum != null) {
      json['taskNum'] = taskNum;
    }
    if (taskStatus != null) {
      json['taskStatus'] = taskStatus;
    }
    if (taskTime != null) {
      json['taskTime'] = taskTime;
    }
    if (taskType != null) {
      json['taskType'] = taskType;
    }
    if (totalAmount != null) {
      json['totalAmount'] = totalAmount;
    }
    if (totalDistance != null) {
      json['totalDistance'] = totalDistance;
    }
    if (updateTime != null) {
      json['updateTime'] = updateTime;
    }
    if (userConfirmedAt != null) {
      json['userConfirmedAt'] = userConfirmedAt;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    if (waypoints != null) {
      json['waypoints'] = waypoints;
    }
    return json;
  }
}

/// 契约 components.schemas.TokenRefreshVO
class ApiTokenRefreshVO {
  final String? token;

  const ApiTokenRefreshVO({this.token});

  factory ApiTokenRefreshVO.fromJson(Map<String, dynamic> json) => ApiTokenRefreshVO(
    token: json['token'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (token != null) {
      json['token'] = token;
    }
    return json;
  }
}

/// 契约 components.schemas.TradeStatsVO
class ApiTradeStatsVO {
  final int? boughtOrderCount;
  final int? completedTradeCount;
  final int? pendingReviewCount;
  final int? publishedTaskCount;
  final int? soldOrderCount;
  final int? totalOrderCount;

  const ApiTradeStatsVO({this.boughtOrderCount, this.completedTradeCount, this.pendingReviewCount, this.publishedTaskCount, this.soldOrderCount, this.totalOrderCount});

  factory ApiTradeStatsVO.fromJson(Map<String, dynamic> json) => ApiTradeStatsVO(
    boughtOrderCount: (json['boughtOrderCount'] as num?)?.toInt(),
    completedTradeCount: (json['completedTradeCount'] as num?)?.toInt(),
    pendingReviewCount: (json['pendingReviewCount'] as num?)?.toInt(),
    publishedTaskCount: (json['publishedTaskCount'] as num?)?.toInt(),
    soldOrderCount: (json['soldOrderCount'] as num?)?.toInt(),
    totalOrderCount: (json['totalOrderCount'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (boughtOrderCount != null) {
      json['boughtOrderCount'] = boughtOrderCount;
    }
    if (completedTradeCount != null) {
      json['completedTradeCount'] = completedTradeCount;
    }
    if (pendingReviewCount != null) {
      json['pendingReviewCount'] = pendingReviewCount;
    }
    if (publishedTaskCount != null) {
      json['publishedTaskCount'] = publishedTaskCount;
    }
    if (soldOrderCount != null) {
      json['soldOrderCount'] = soldOrderCount;
    }
    if (totalOrderCount != null) {
      json['totalOrderCount'] = totalOrderCount;
    }
    return json;
  }
}

/// 契约 components.schemas.UploadVO
class ApiUploadVO {
  final String? createTime;
  final int? fileSize;
  final String? fileSuffix;
  final String? fileUrl;
  final int? id;
  final String? mimeType;
  final String? orderNum;
  final String? originalName;
  final String? storagePath;
  final String? uploadId;
  final String? uploadStatus;
  final int? userId;

  const ApiUploadVO({this.createTime, this.fileSize, this.fileSuffix, this.fileUrl, this.id, this.mimeType, this.orderNum, this.originalName, this.storagePath, this.uploadId, this.uploadStatus, this.userId});

  factory ApiUploadVO.fromJson(Map<String, dynamic> json) => ApiUploadVO(
    createTime: json['createTime'] as String?,
    fileSize: (json['fileSize'] as num?)?.toInt(),
    fileSuffix: json['fileSuffix'] as String?,
    fileUrl: json['fileUrl'] as String?,
    id: (json['id'] as num?)?.toInt(),
    mimeType: json['mimeType'] as String?,
    orderNum: json['orderNum'] as String?,
    originalName: json['originalName'] as String?,
    storagePath: json['storagePath'] as String?,
    uploadId: json['uploadId'] as String?,
    uploadStatus: json['uploadStatus'] as String?,
    userId: (json['userId'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (createTime != null) {
      json['createTime'] = createTime;
    }
    if (fileSize != null) {
      json['fileSize'] = fileSize;
    }
    if (fileSuffix != null) {
      json['fileSuffix'] = fileSuffix;
    }
    if (fileUrl != null) {
      json['fileUrl'] = fileUrl;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (mimeType != null) {
      json['mimeType'] = mimeType;
    }
    if (orderNum != null) {
      json['orderNum'] = orderNum;
    }
    if (originalName != null) {
      json['originalName'] = originalName;
    }
    if (storagePath != null) {
      json['storagePath'] = storagePath;
    }
    if (uploadId != null) {
      json['uploadId'] = uploadId;
    }
    if (uploadStatus != null) {
      json['uploadStatus'] = uploadStatus;
    }
    if (userId != null) {
      json['userId'] = userId;
    }
    return json;
  }
}

/// 契约 components.schemas.UserLoginDto
class ApiUserLoginDto {
  final String? password;
  final String? userName;

  const ApiUserLoginDto({this.password, this.userName});

  factory ApiUserLoginDto.fromJson(Map<String, dynamic> json) => ApiUserLoginDto(
    password: json['password'] as String?,
    userName: json['userName'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (password != null) {
      json['password'] = password;
    }
    if (userName != null) {
      json['userName'] = userName;
    }
    return json;
  }
}

/// 契约 components.schemas.UserLoginVO
class ApiUserLoginVO {
  final String? refreshToken;
  final String? token;

  const ApiUserLoginVO({this.refreshToken, this.token});

  factory ApiUserLoginVO.fromJson(Map<String, dynamic> json) => ApiUserLoginVO(
    refreshToken: json['refreshToken'] as String?,
    token: json['token'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (refreshToken != null) {
      json['refreshToken'] = refreshToken;
    }
    if (token != null) {
      json['token'] = token;
    }
    return json;
  }
}

/// 契约 components.schemas.UserRegisterDto
class ApiUserRegisterDto {
  final String? password;
  final String? userName;

  const ApiUserRegisterDto({this.password, this.userName});

  factory ApiUserRegisterDto.fromJson(Map<String, dynamic> json) => ApiUserRegisterDto(
    password: json['password'] as String?,
    userName: json['userName'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (password != null) {
      json['password'] = password;
    }
    if (userName != null) {
      json['userName'] = userName;
    }
    return json;
  }
}

/// 契约 components.schemas.WaybillAssessmentVO
class ApiWaybillAssessmentVO {
  final String? assessmentId;
  final ApiDispatchEvaluationVO? evaluation;
  final String? expiresAt;
  final bool? orderAllowed;
  final ApiDispatchQuoteVO? quote;

  const ApiWaybillAssessmentVO({this.assessmentId, this.evaluation, this.expiresAt, this.orderAllowed, this.quote});

  factory ApiWaybillAssessmentVO.fromJson(Map<String, dynamic> json) => ApiWaybillAssessmentVO(
    assessmentId: json['assessmentId'] as String?,
    evaluation: (json['evaluation'] == null ? null : ApiDispatchEvaluationVO.fromJson(json['evaluation'] as Map<String, dynamic>)),
    expiresAt: json['expiresAt'] as String?,
    orderAllowed: json['orderAllowed'] as bool?,
    quote: (json['quote'] == null ? null : ApiDispatchQuoteVO.fromJson(json['quote'] as Map<String, dynamic>)),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (assessmentId != null) {
      json['assessmentId'] = assessmentId;
    }
    if (evaluation != null) {
      json['evaluation'] = evaluation?.toJson();
    }
    if (expiresAt != null) {
      json['expiresAt'] = expiresAt;
    }
    if (orderAllowed != null) {
      json['orderAllowed'] = orderAllowed;
    }
    if (quote != null) {
      json['quote'] = quote?.toJson();
    }
    return json;
  }
}

/// 契约 components.schemas.WaybillDraftDTO
class ApiWaybillDraftDTO {
  final int? expectedRevision;
  final Map<String, dynamic> fields;
  final int schemaVersion;
  final int step;

  const ApiWaybillDraftDTO({this.expectedRevision, required this.fields, required this.schemaVersion, required this.step});

  factory ApiWaybillDraftDTO.fromJson(Map<String, dynamic> json) => ApiWaybillDraftDTO(
    expectedRevision: (json['expectedRevision'] as num?)?.toInt(),
    fields: json['fields'] as Map<String, dynamic>,
    schemaVersion: ((json['schemaVersion'] as num?)?.toInt() ?? 0),
    step: ((json['step'] as num?)?.toInt() ?? 0),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (expectedRevision != null) {
      json['expectedRevision'] = expectedRevision;
    }
    json['fields'] = fields;
    json['schemaVersion'] = schemaVersion;
    json['step'] = step;
    return json;
  }
}

/// 契约 components.schemas.WaybillDraftVO
class ApiWaybillDraftVO {
  final Map<String, dynamic>? fields;
  final int? revision;
  final int? schemaVersion;
  final int? step;
  final String? updatedAt;

  const ApiWaybillDraftVO({this.fields, this.revision, this.schemaVersion, this.step, this.updatedAt});

  factory ApiWaybillDraftVO.fromJson(Map<String, dynamic> json) => ApiWaybillDraftVO(
    fields: json['fields'] as Map<String, dynamic>?,
    revision: (json['revision'] as num?)?.toInt(),
    schemaVersion: (json['schemaVersion'] as num?)?.toInt(),
    step: (json['step'] as num?)?.toInt(),
    updatedAt: json['updatedAt'] as String?,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (fields != null) {
      json['fields'] = fields;
    }
    if (revision != null) {
      json['revision'] = revision;
    }
    if (schemaVersion != null) {
      json['schemaVersion'] = schemaVersion;
    }
    if (step != null) {
      json['step'] = step;
    }
    if (updatedAt != null) {
      json['updatedAt'] = updatedAt;
    }
    return json;
  }
}

/// 契约 components.schemas.WaypointDto
class ApiWaypointDto {
  final double? altitude;
  final double? latitude;
  final double? longitude;
  final int? orderIndex;

  const ApiWaypointDto({this.altitude, this.latitude, this.longitude, this.orderIndex});

  factory ApiWaypointDto.fromJson(Map<String, dynamic> json) => ApiWaypointDto(
    altitude: (json['altitude'] as num?)?.toDouble(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    orderIndex: (json['orderIndex'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (altitude != null) {
      json['altitude'] = altitude;
    }
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    if (longitude != null) {
      json['longitude'] = longitude;
    }
    if (orderIndex != null) {
      json['orderIndex'] = orderIndex;
    }
    return json;
  }
}

/// 契约 components.schemas.WaypointVo
class ApiWaypointVo {
  final double? altitude;
  final int? id;
  final double? latitude;
  final double? longitude;
  final int? orderIndex;

  const ApiWaypointVo({this.altitude, this.id, this.latitude, this.longitude, this.orderIndex});

  factory ApiWaypointVo.fromJson(Map<String, dynamic> json) => ApiWaypointVo(
    altitude: (json['altitude'] as num?)?.toDouble(),
    id: (json['id'] as num?)?.toInt(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    orderIndex: (json['orderIndex'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (altitude != null) {
      json['altitude'] = altitude;
    }
    if (id != null) {
      json['id'] = id;
    }
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    if (longitude != null) {
      json['longitude'] = longitude;
    }
    if (orderIndex != null) {
      json['orderIndex'] = orderIndex;
    }
    return json;
  }
}
