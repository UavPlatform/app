import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/amap_config.dart';
import 'task_provider.dart';

class MissingAndroidMapKeyException implements Exception {
  const MissingAndroidMapKeyException();
}

final amapMapConfigProvider = FutureProvider<AmapConfig>((ref) async {
  final result = await ref.watch(taskApiProvider).getAmapConfig();
  if (!result.success || result.data == null) {
    throw StateError('地图配置不可用');
  }
  if (result.data!.key.trim().isEmpty) {
    throw const MissingAndroidMapKeyException();
  }
  return result.data!;
});
