import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// 一条 POI 搜索结果（高德 Android SDK `PoiSearch`）。
class PlaceSearchResult {
  PlaceSearchResult.fromMap(Map<dynamic, dynamic> map)
    : id = map['id'] as String? ?? '',
      name = map['name'] as String? ?? '',
      address = map['address'] as String? ?? '',
      district = map['district'] as String? ?? '',
      point = LatLng(
        (map['latitude'] as num?)?.toDouble() ?? double.nan,
        (map['longitude'] as num?)?.toDouble() ?? double.nan,
      ),
      distanceMeters = (map['distance'] as num?)?.toDouble();

  final String id;
  final String name;
  final String address;
  final String district;
  final LatLng point;
  final double? distanceMeters;

  bool get isValid =>
      name.trim().isNotEmpty &&
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;

  /// 用于回填表单的一行位置描述；没有地址时退回行政区。
  String get description =>
      [district, address].where((part) => part.trim().isNotEmpty).join(' ');
}

typedef PlaceLabel = ({String name, String address});

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 高德 POI 关键字搜索通道：结果直接来自 SDK，不经过后端。
class PlaceSearch {
  static const channel = MethodChannel('com.fuwaki.app/place_search');

  /// Describe the selected GCJ-02 point relative to the nearest returned POI.
  Future<PlaceLabel?> reverse({
    required String key,
    required LatLng point,
  }) async {
    final raw = await channel
        .invokeMapMethod<String, dynamic>('reverse', {
          'key': key.trim(),
          'latitude': point.latitude,
          'longitude': point.longitude,
        })
        .timeout(const Duration(seconds: 16));
    final address = (raw?['address'] as String? ?? '').trim();
    final pois = raw?['pois'] as List<dynamic>? ?? const [];
    const distance = Distance(calculator: Haversine(), roundResult: false);
    PlaceSearchResult? nearest;
    var meters = double.infinity;
    for (final entry in pois.whereType<Map<dynamic, dynamic>>()) {
      final poi = PlaceSearchResult.fromMap(entry);
      if (!poi.isValid) continue;
      final candidate = distance.as(LengthUnit.Meter, poi.point, point);
      if (candidate < meters) {
        nearest = poi;
        meters = candidate;
      }
    }
    if (nearest == null) {
      return address.isEmpty ? null : (name: address, address: '');
    }
    final name = nearest.name.trim();
    if (meters < 1) return (name: name, address: address);
    final bearing = normalizeBearing(distance.bearing(nearest.point, point));
    const directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
    final direction = directions[((bearing + 22.5) / 45).floor() % 8];
    return (name: '$name$direction侧约${meters.round()}米', address: address);
  }

  /// [key] 与地图/定位共用 `GET /config/map` 下发的 Android SDK key。
  /// [center] 为排序原点（当前传定位坐标，非相机中心）。
  Future<List<PlaceSearchResult>> search({
    required String key,
    required String keyword,
    String? city,
    LatLng? center,
    int limit = 20,
  }) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const [];
    if (key.trim().isEmpty) throw const PlaceSearchException('地图服务暂不可用，无法搜索');
    try {
      final raw = await channel
          .invokeMethod<List<dynamic>>('search', {
            'key': key.trim(),
            'keyword': trimmed,
            'city': city?.trim() ?? '',
            'limit': limit,
            if (center != null)
              'center': {
                'latitude': center.latitude,
                'longitude': center.longitude,
              },
          })
          .timeout(const Duration(seconds: 20));
      return (raw ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map(PlaceSearchResult.fromMap)
          .where((result) => result.isValid)
          .toList(growable: false);
    } on PlatformException catch (error) {
      throw PlaceSearchException(error.message ?? '搜索失败，请稍后重试');
    } on TimeoutException {
      throw const PlaceSearchException('搜索超时，请重试');
    } on MissingPluginException {
      throw const PlaceSearchException('当前平台不支持地点搜索');
    }
  }
}

final placeSearchProvider = Provider((ref) => PlaceSearch());
