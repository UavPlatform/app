import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Owns the channel for one native map; pages only need camera movement.
class MissionMapController {
  MethodChannel? _channel;
  int? _viewId;
  bool get isAttached => _channel != null;

  static Map<String, double>? coordinates(LatLng? point) => point == null
      ? null
      : {'latitude': point.latitude, 'longitude': point.longitude};

  void attach(int viewId, {required void Function(LatLng) onTap}) {
    dispose();
    _viewId = viewId;
    final channel = MethodChannel('com.fuwaki.app/amap/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method != 'tap') return;
      final data = call.arguments as Map;
      onTap(
        LatLng(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        ),
      );
    });
  }

  Future<void> update(Map<String, Object?> state) async {
    await _channel?.invokeMethod<void>('update', state);
  }

  Future<void> move(LatLng point, double zoom) async {
    await _channel?.invokeMethod<void>('move', {
      'center': coordinates(point),
      'zoom': zoom,
    });
  }

  void detach(int viewId) {
    if (_viewId == viewId) dispose();
  }

  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    _viewId = null;
  }
}
