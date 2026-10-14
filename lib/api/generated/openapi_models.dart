// GENERATED — DO NOT EDIT.
// 契约模型：后端 components.schemas 的 Dart 映射。
// 生成命令：dart run tool/openapi_gen.dart
// 事实源：openapi/drone-backend.openapi.json (sha256: f3fdf76770f2080f242142fe33921bd4b291a34b02cbab57cb2d252ab1f14b03)
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

/// 契约 components.schemas.PullCredentialsVO
class ApiPullCredentialsVO {
  final bool? ackConfirmed;
  final String? liveState;
  final String? roomId;
  final int? sdkAppId;
  final String? userId;
  final String? userSig;
  final String? wsUrl;

  const ApiPullCredentialsVO({this.ackConfirmed, this.liveState, this.roomId, this.sdkAppId, this.userId, this.userSig, this.wsUrl});

  factory ApiPullCredentialsVO.fromJson(Map<String, dynamic> json) => ApiPullCredentialsVO(
    ackConfirmed: json['ackConfirmed'] as bool?,
    liveState: json['liveState'] as String?,
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
