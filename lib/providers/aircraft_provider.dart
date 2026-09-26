import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/aircraft_api.dart';
import '../api/generated/openapi_models.dart';
import 'auth_provider.dart';

final aircraftApiProvider = Provider<AircraftApi>(
  (ref) => AircraftApi(ref.watch(httpClientProvider)),
);

class AircraftModelsState {
  final List<ApiAircraftModelVO> models;
  final bool loading;
  final String? error;

  const AircraftModelsState({
    this.models = const [],
    this.loading = false,
    this.error,
  });

  AircraftModelsState copyWith({
    List<ApiAircraftModelVO>? models,
    bool? loading,
    String? error,
  }) {
    return AircraftModelsState(
      models: models ?? this.models,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// 机型目录（绑机/应征选机型的数据源）；成功加载过一次即复用，避免重复往返。
class AircraftModelsNotifier extends StateNotifier<AircraftModelsState> {
  final AircraftApi _api;

  AircraftModelsNotifier(this._api) : super(const AircraftModelsState());

  Future<void> load({bool force = false}) async {
    if (state.loading) return;
    if (!force && state.models.isNotEmpty) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listModels();
      if (!mounted) return;
      if (result.success && result.data != null) {
        state = state.copyWith(loading: false, models: result.data!);
      } else {
        state = state.copyWith(
          loading: false,
          error: result.message ?? '获取机型目录失败',
        );
      }
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: '网络请求失败');
    }
  }
}

final aircraftModelsProvider =
    StateNotifierProvider<AircraftModelsNotifier, AircraftModelsState>(
  (ref) => AircraftModelsNotifier(ref.watch(aircraftApiProvider)),
);
