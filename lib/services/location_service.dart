import 'package:flutter/services.dart';

class AmapLocationResult {
  final String? city;
  final String? province;
  final String? district;
  final String? address;
  final double? latitude;
  final double? longitude;

  AmapLocationResult({
    this.city,
    this.province,
    this.district,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory AmapLocationResult.fromMap(Map<dynamic, dynamic> map) {
    return AmapLocationResult(
      city: map['city'] as String?,
      province: map['province'] as String?,
      district: map['district'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  String get displayCity {
    if (city != null && city!.isNotEmpty) return city!;
    return province ?? '未知城市';
  }
}

class LocationService {
  static const _channel = MethodChannel('com.fuwaki.app/location');

  Future<void> setApiKey(String key) async {
    await _channel.invokeMethod('setApiKey', {'key': key});
  }

  Future<AmapLocationResult?> getCurrentLocation() async {
    try {
      final result = await _channel.invokeMethod('getLocation').timeout(
        const Duration(seconds: 30),
      );
      final map = result as Map<dynamic, dynamic>;

      if (map['errorCode'] != null) return null;

      return AmapLocationResult.fromMap(map);
    } catch (_) {
      return null;
    }
  }
}
