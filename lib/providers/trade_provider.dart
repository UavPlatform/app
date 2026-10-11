import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/trade_api.dart';
import 'auth_provider.dart';

final tradeStatsProvider = FutureProvider.autoDispose<TradeStats>((ref) async {
  ref.watch(authProvider.select((state) => state.user?.userId));
  final result = await TradeApi(ref.watch(httpClientProvider)).stats();
  if (!result.success || result.data == null) {
    throw Exception(result.message ?? '交易统计加载失败');
  }
  return result.data!;
});
