import 'package:flutter/services.dart';

class DispatchLocationFix {
  DispatchLocationFix.fromMap(Map<dynamic, dynamic> map)
    : latitude = (map['latitude'] as num?)?.toDouble(),
      longitude = (map['longitude'] as num?)?.toDouble(),
      accuracyMeters = (map['accuracyMeters'] as num?)?.toDouble(),
      capturedAt = map['capturedAt'] as int?,
      coordinateSystem = map['coordinateSystem'] as String?,
      mocked = map['mocked'] as bool?;
  final double? latitude, longitude, accuracyMeters;
  final int? capturedAt;
  final String? coordinateSystem;
  final bool? mocked;
  bool validAt(DateTime now) =>
      latitude != null &&
      longitude != null &&
      accuracyMeters != null &&
      capturedAt != null &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      accuracyMeters!.isFinite &&
      accuracyMeters! >= 0 &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180 &&
      coordinateSystem == 'GCJ02' &&
      mocked == false &&
      capturedAt! <= now.millisecondsSinceEpoch + 30000 &&
      capturedAt! > now.millisecondsSinceEpoch - 300000;
}

class DispatchLocation {
  static const channel = MethodChannel('com.fuwaki.app/location');
  Future<DispatchLocationFix> locate(String key) async {
    if (key.trim().isEmpty) throw StateError('定位配置不可用');
    await channel.invokeMethod('setApiKey', {'key': key});
    final raw = await channel
        .invokeMethod<Map<dynamic, dynamic>>('getDispatchLocation')
        .timeout(const Duration(seconds: 30));
    if (raw == null) throw StateError('定位不可用');
    final fix = DispatchLocationFix.fromMap(raw);
    if (!fix.validAt(DateTime.now())) throw StateError('定位已过期或无效，请重新定位');
    return fix;
  }
}
