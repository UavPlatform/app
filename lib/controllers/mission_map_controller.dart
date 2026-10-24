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

  void attach(
    int viewId, {
    required void Function(LatLng) onTap,
    void Function(double?)? onRemainingDistance,
    void Function(String)? onOrderMarkerTap,
  }) {
    dispose();
    _viewId = viewId;
    final channel = MethodChannel('com.fuwaki.app/amap/$viewId');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'remainingDistance') {
        onRemainingDistance?.call((call.arguments as num?)?.toDouble());
        return;
      }
      if (call.method == 'orderMarkerTap') {
        final id = call.arguments;
        if (id is String) onOrderMarkerTap?.call(id);
        return;
      }
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

  Future<void> move(LatLng point, double zoom, {bool gps = false}) async {
    await _channel?.invokeMethod<void>('move', {
      'center': coordinates(point),
      'zoom': zoom,
      'centerIsGps': gps,
    });
  }

  Future<void> fit(List<LatLng> points, {double bottomInset = 0}) async {
    await _channel?.invokeMethod<void>('fit', {
      'points': points.map(coordinates).toList(),
      'bottomInset': bottomInset,
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
