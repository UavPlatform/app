import 'package:latlong2/latlong.dart';
import '../services/place_search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/amap_config.dart';
import '../api/map_config_api.dart';
import 'auth_provider.dart';

class MissingAndroidMapKeyException implements Exception {
  const MissingAndroidMapKeyException();
}

final mapConfigApiProvider = Provider<MapConfigApi>(
  (ref) => MapConfigApi(ref.watch(httpClientProvider)),
);

final amapMapConfigProvider = FutureProvider<AmapConfig>((ref) async {
  final result = await ref.watch(mapConfigApiProvider).getAmapConfig();
  if (!result.success || result.data == null) {
    throw StateError('地图配置不可用');
  }
  if (result.data!.key.trim().isEmpty) {
    throw const MissingAndroidMapKeyException();
  }
  return result.data!;
});

final mapPointLabelProvider = FutureProvider.autoDispose
    .family<PlaceLabel?, LatLng>((ref, point) async {
      final search = ref.watch(placeSearchProvider);
      try {
        final config = await ref.watch(amapMapConfigProvider.future);
        return await search.reverse(key: config.key, point: point);
      } catch (_) {
        return null;
      }
    });

/// Old waybills may have only coordinates; resolve them for display without rewriting the order.
PlaceLabel? orderEndpointLabel(
  WidgetRef ref,
  Map<String, dynamic> fields,
  String side,
) {
  final name = fields['$side.place']?.toString().trim() ?? '';
  final address = fields['$side.placeAddress']?.toString().trim() ?? '';
  if (name.isNotEmpty || address.isNotEmpty) {
    return (name: name, address: address);
  }
  final lat = double.tryParse(fields['$side.lat']?.toString() ?? '');
  final lng = double.tryParse(fields['$side.lng']?.toString() ?? '');
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat.abs() > 90 ||
      lng.abs() > 180) {
    return null;
  }
  return ref.watch(mapPointLabelProvider(LatLng(lat, lng))).valueOrNull;
}
