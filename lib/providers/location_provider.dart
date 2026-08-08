import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../api/task_api.dart';
import 'task_provider.dart';

class LocationState {
  final String city;
  final bool loading;
  final double? latitude;
  final double? longitude;

  const LocationState({
    this.city = '定位中...',
    this.loading = true,
    this.latitude,
    this.longitude,
  });

  LocationState copyWith({
    String? city,
    bool? loading,
    double? latitude,
    double? longitude,
  }) {
    return LocationState(
      city: city ?? this.city,
      loading: loading ?? this.loading,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
        debugPrint('[Location] getAmapConfig success=${r.success} key=${r.data?.key}');
        if (r.success && r.data != null) {
          _amapKey = r.data!.key;
          await _service.setApiKey(_amapKey!);
        }
      } catch (e) {
        debugPrint('[Location] getAmapConfig failed: $e');
      }
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
      latitude: result?.latitude,
      longitude: result?.longitude,
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
