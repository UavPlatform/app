import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../models/amap_config.dart';
import 'map_provider.dart';

class LocationState {
  final String city;
  final String? address;
  final bool loading;
  final double? latitude;
  final double? longitude;

  const LocationState({
    this.city = '定位中...',
    this.address,
    this.loading = true,
    this.latitude,
    this.longitude,
  });

  LocationState copyWith({
    String? city,
    String? address,
    bool? loading,
    double? latitude,
    double? longitude,
  }) {
    return LocationState(
      city: city ?? this.city,
      address: address ?? this.address,
      loading: loading ?? this.loading,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _service;
  final Future<AmapConfig> Function() _getConfig;
  bool _running = false;
  String? _amapKey;

  LocationNotifier(this._getConfig, {LocationService? service})
    : _service = service ?? LocationService(),
      super(const LocationState()) {
    _init();
  }

  Future<void> _init() async {
    if (_running) return;
    _running = true;

    if (_amapKey == null) {
      try {
        final config = await _getConfig();
        if (!mounted) return;
        if (config.key.trim().isNotEmpty) {
          _amapKey = config.key.trim();
          await _service.setApiKey(_amapKey!);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    final result = await _service.getCurrentLocation();
    if (!mounted) return;
    state = LocationState(
      city: result?.displayCity ?? '定位不可用，请检查权限和定位开关',
      address: result?.address,
      loading: false,
      latitude: result?.latitude,
      longitude: result?.longitude,
    );
    _running = false;
  }

  Future<void> refresh() async {
    if (_running) return;
    state = state.copyWith(loading: true);
    await _init();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(() => ref.read(amapMapConfigProvider.future)),
);
