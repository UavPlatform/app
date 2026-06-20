import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../api/task/task_api.dart';
import 'auth_provider.dart';

final taskApiProvider = Provider<TaskApi>(
  (ref) => TaskApi(ref.watch(httpClientProvider)),
);

class LocationState {
  final String city;
  final bool loading;

  const LocationState({this.city = '定位中...', this.loading = true});

  LocationState copyWith({String? city, bool? loading}) {
    return LocationState(
      city: city ?? this.city,
      loading: loading ?? this.loading,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _service = LocationService();
  final TaskApi _taskApi;
  bool _running = false;
  String? _amapKey;

  LocationNotifier(this._taskApi) : super(const LocationState()) {
    _init();
  }

  Future<void> _init() async {
    if (_running) return;
    _running = true;

    if (_amapKey == null) {
      try {
        final r = await _taskApi.getAmapConfig();
        if (r.success && r.data != null) {
          _amapKey = r.data!.key;
          await _service.setApiKey(_amapKey!);
        }
      } catch (_) {}
    }

    if (_amapKey == null) {
      state = state.copyWith(city: '服务暂不可用', loading: false);
      _running = false;
      return;
    }

    final result = await _service.getCurrentLocation();
    state = state.copyWith(
      city: result?.displayCity ?? '未知城市',
      loading: false,
    );
    _running = false;
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    _running = false;
    await _init();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(ref.watch(taskApiProvider)),
);
