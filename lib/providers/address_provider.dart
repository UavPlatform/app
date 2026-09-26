import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/address_api.dart';
import '../models/address_vo.dart';
import 'auth_provider.dart';

final addressApiProvider = Provider<AddressApi>(
  (ref) => AddressApi(ref.watch(httpClientProvider)),
);

class AddressListState {
  final List<AddressVo> addresses;
  final bool loading;
  final String? error;

  const AddressListState({
    this.addresses = const [],
    this.loading = true,
    this.error,
  });

  AddressListState copyWith({
    List<AddressVo>? addresses,
    bool? loading,
    String? error,
  }) {
    return AddressListState(
      addresses: addresses ?? this.addresses,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// 地址簿：后端为主数据源，本地 SharedPreferences 做缓存。
/// 加载时先展示缓存（秒开），再拉后端刷新并写回缓存；网络失败时保留缓存数据。
class AddressNotifier extends StateNotifier<AddressListState> {
  final AddressApi _api;
  static const _cacheKey = 'address_cache_v1';

  AddressNotifier(this._api) : super(const AddressListState()) {
    _init();
  }

  Future<void> _init() async {
    final cached = await _readCache();
    if (cached != null && cached.isNotEmpty && mounted) {
      state = AddressListState(addresses: cached, loading: true);
    }
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _api.listAddresses();
      if (!result.success || result.data == null) {
        state = state.copyWith(loading: false, error: result.message ?? '获取地址失败');
        return;
      }
      state = state.copyWith(loading: false, addresses: result.data!);
      await _writeCache(result.data!);
    } catch (_) {
      // 网络失败：保留缓存展示，仅提示
      state = state.copyWith(loading: false, error: '网络异常，展示本地缓存数据');
    }
  }

  Future<AddressVo?> createAddress(AddressVo address) async {
    try {
      final result = await _api.createAddress(address.toJson());
      if (!result.success || result.data == null) return null;
      state = state.copyWith(addresses: [...state.addresses, result.data!]);
      await _writeCache(state.addresses);
      return result.data;
    } catch (_) {
      return null;
    }
  }

  Future<AddressVo?> updateAddress(AddressVo address) async {
    try {
      final result = await _api.updateAddress(address.toJson());
      if (!result.success || result.data == null) return null;
      final updated = result.data!;
      state = state.copyWith(
        addresses: state.addresses.map((a) => a.id == updated.id ? updated : a).toList(),
      );
      await _writeCache(state.addresses);
      return updated;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteAddress(int id) async {
    try {
      final result = await _api.deleteAddress(id);
      if (!result.success) return false;
      state = state.copyWith(addresses: state.addresses.where((a) => a.id != id).toList());
      await _writeCache(state.addresses);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setDefault(int id) async {
    try {
      final result = await _api.setDefault(id);
      if (!result.success) return false;
      final updated = state.addresses
          .map((a) => a.copyWith(isDefault: a.id == id))
          .toList();
      state = state.copyWith(addresses: updated);
      await _writeCache(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- 本地缓存 ----

  Future<List<AddressVo>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => AddressVo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<AddressVo> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(addresses.map((a) => a.toJson()).toList()),
      );
    } catch (_) {
      // 缓存写失败不影响主流程
    }
  }
}

final addressProvider = StateNotifierProvider<AddressNotifier, AddressListState>(
  (ref) => AddressNotifier(ref.watch(addressApiProvider)),
);
