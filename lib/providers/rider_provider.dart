import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/rider_api.dart';
import '../models/rider_vo.dart';
import 'auth_provider.dart';

final riderApiProvider = Provider<RiderApi>(
  (ref) => RiderApi(ref.watch(httpClientProvider)),
);

class RiderListState {
  final List<RiderVo> riders;
  final bool loading;
  final String? error;

  const RiderListState({this.riders = const [], this.loading = true, this.error});

  RiderListState copyWith({List<RiderVo>? riders, bool? loading, String? error}) {
    return RiderListState(
      riders: riders ?? this.riders,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class RiderListNotifier extends StateNotifier<RiderListState> {
  final RiderApi _api;

  RiderListNotifier(this._api) : super(const RiderListState()) {
    loadRiders();
  }

  Future<void> loadRiders() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.getRecommended();
      if (!result.success || result.data == null) {
        final msg = result.message ?? '加载飞手列表失败';
        state = state.copyWith(loading: false, error: msg);
        return;
      }
      state = state.copyWith(loading: false, riders: result.data!);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        state = state.copyWith(loading: false, error: '请求未授权(401)，接口可能暂未上线或登录已过期');
      } else {
        state = state.copyWith(loading: false, error: '网络请求失败: $e');
      }
    }
  }
}

final riderListProvider = StateNotifierProvider<RiderListNotifier, RiderListState>(
  (ref) => RiderListNotifier(ref.watch(riderApiProvider)),
);
