import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/rider_account_api.dart';
import '../models/rider_uav.dart';
import 'auth_provider.dart';

final riderAccountApiProvider = Provider<RiderAccountApi>(
  (ref) => RiderAccountApi(ref.watch(httpClientProvider)),
);


// 飞手注册
class RiderRegisterState {
  final bool loading;
  final String? error;

  const RiderRegisterState({this.loading = false, this.error});

  RiderRegisterState copyWith({bool? loading, String? error}) {
    return RiderRegisterState(
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class RiderRegisterNotifier extends StateNotifier<RiderRegisterState> {
  final RiderAccountApi _api;

  RiderRegisterNotifier(this._api) : super(const RiderRegisterState());

  Future<bool> register({
    required String userName,
    required String password,
    String? djiId,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.register(
        userName: userName,
        password: password,
        djiId: djiId,
      );
      if (!result.success || result.data == null) {
        state = state.copyWith(loading: false, error: result.message ?? '注册失败');
        return false;
      }
      state = state.copyWith(loading: false);
      return true;
    } catch (_) {
      state = state.copyWith(loading: false, error: '网络请求失败');
      return false;
    }
  }
}

final riderRegisterProvider =
    StateNotifierProvider<RiderRegisterNotifier, RiderRegisterState>(
  (ref) => RiderRegisterNotifier(ref.watch(riderAccountApiProvider)),
);


// 无人机管理
class DroneListState {
  final List<RiderUav> drones;
  final bool loading;
  final String? error;

  const DroneListState({this.drones = const [], this.loading = true, this.error});

  DroneListState copyWith({List<RiderUav>? drones, bool? loading, String? error}) {
    return DroneListState(
      drones: drones ?? this.drones,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class DroneListNotifier extends StateNotifier<DroneListState> {
  final RiderAccountApi _api;

  DroneListNotifier(this._api) : super(const DroneListState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listDrones();
      if (result.success && result.data != null) {
        state = state.copyWith(loading: false, drones: result.data!);
      } else {
        state = state.copyWith(loading: false, error: result.message ?? '加载失败');
      }
    } catch (_) {
      state = state.copyWith(loading: false, error: '加载失败');
    }
  }

  Future<bool> bindDrone(String djiId, {required int aircraftModelId}) async {
    try {
      final result = await _api.bindDrone(
        djiId,
        aircraftModelId: aircraftModelId,
      );
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '绑定失败');
        return false;
      }
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(error: '绑定失败');
      return false;
    }
  }

  Future<bool> unbindDrone(String djiId) async {
    try {
      final result = await _api.unbindDrone(djiId);
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '解绑失败');
        return false;
      }
      state = state.copyWith(
        drones: state.drones.where((d) => d.djiId != djiId).toList(),
      );
      return true;
    } catch (_) {
      state = state.copyWith(error: '解绑失败');
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final droneListProvider =
    StateNotifierProvider<DroneListNotifier, DroneListState>(
  (ref) => DroneListNotifier(ref.watch(riderAccountApiProvider)),
);
