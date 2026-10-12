import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/generated/openapi_models.dart';
import '../api/rider_info_api.dart';
import 'auth_provider.dart';

final riderInfoApiProvider = Provider<RiderInfoApi>(
  (ref) => RiderInfoApi(ref.watch(httpClientProvider)),
);

/// 本人飞手资料；失败时抛出服务端文案，交由 UI 展示重试。
final riderInfoProvider = FutureProvider.autoDispose<ApiRiderInfoVO>((ref) async {
  final result = await ref.watch(riderInfoApiProvider).getInfo();
  if (!result.success || result.data == null) {
    throw result.message ?? '飞手资料加载失败';
  }
  return result.data!;
});
