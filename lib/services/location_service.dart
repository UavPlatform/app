import 'dart:async';

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
  Timer? _sdkTimeout;
  Completer<dynamic>? _sdkRequest;

  void dispose() {
    _sdkTimeout?.cancel();
    final request = _sdkRequest;
    if (request != null && !request.isCompleted) request.complete(null);
  }

  Future<void> setApiKey(String key) async {
    await _channel.invokeMethod('setApiKey', {'key': key});
  }

  Future<AmapLocationResult?> getCurrentLocation() async {
    final request = Completer<dynamic>();
    _sdkRequest = request;
    final timeout = Timer(const Duration(seconds: 30), () {
      if (!request.isCompleted) request.complete(null);
    });
    _sdkTimeout = timeout;
    unawaited(
      _channel
          .invokeMethod('getLocation')
          .then<void>(
            (result) {
              if (!request.isCompleted) request.complete(result);
            },
            onError: (Object error, StackTrace stack) {
              if (!request.isCompleted) request.completeError(error, stack);
            },
          ),
    );
    try {
      final result = await request.future;
      if (result == null) return null;
      final map = result as Map<dynamic, dynamic>;

      if (map['errorCode'] != null) return null;

      return AmapLocationResult.fromMap(map);
    } catch (e) {
      return null;
    } finally {
      timeout.cancel();
      if (_sdkRequest == request) {
        _sdkRequest = null;
        _sdkTimeout = null;
      }
    }
  }
}
