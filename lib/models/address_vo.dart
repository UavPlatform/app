import 'result_model.dart';

class AddressVo {
  final int id;
  final int userId;
  final String contactName;
  final String contactPhone;
  final String province;
  final String city;
  final String district;
  final String detail;
  final double? latitude;
  final double? longitude;
  final String? label;
  final bool isDefault;
  final String? createTime;

  AddressVo({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    required this.province,
    required this.city,
    required this.district,
    required this.detail,
    this.latitude,
    this.longitude,
    this.label,
    this.isDefault = false,
    this.createTime,
  });

  factory AddressVo.fromJson(Map<String, dynamic> json) {
    return AddressVo(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? 0,
      contactName: json['contactName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      province: json['province'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      label: json['label'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'province': province,
      'city': city,
      'district': district,
      'detail': detail,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'isDefault': isDefault,
    };
  }

  AddressVo copyWith({
    int? id,
    int? userId,
    String? contactName,
    String? contactPhone,
    String? province,
    String? city,
    String? district,
    String? detail,
    double? latitude,
    double? longitude,
    String? label,
    bool? isDefault,
  }) {
    return AddressVo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      detail: detail ?? this.detail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
      createTime: createTime,
    );
  }

  /// 列表接口解析（data 为对象数组）
  static Result<List<AddressVo>> parseListResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => (data as List<dynamic>)
        .map((e) => AddressVo.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  /// 单个地址接口解析
  static Result<AddressVo> parseResult(Map<String, dynamic> json) {
    return Result.fromJson(json, (data) => AddressVo.fromJson(data as Map<String, dynamic>));
  }

  String get fullRegion => '$province$city$district';

  String get copyText {
    final sb = StringBuffer();
    sb.writeln('收货人 $contactName');
    sb.writeln('手机号 $contactPhone');
    sb.writeln('所在地区 $fullRegion');
    sb.writeln('详细地址 $detail');
    return sb.toString().trimRight();
  }
}
