import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/token_storage.dart';
import '../services/jwt_decoder.dart';
import '../api/auth/http_client.dart';
import '../api/auth/auth_api.dart';
import '../repositories/auth_repository.dart';

// ============================================================
// 基础设施 Providers
// ============================================================

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('必须在 main.dart 中 override');
});

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(sharedPreferencesProvider)),
);

final httpClientProvider = Provider<HttpClient>(
  (ref) => HttpClient(ref.watch(tokenStorageProvider)),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(httpClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
  ),
);

// ============================================================
// 认证状态
// ============================================================

enum AuthStatus { unknown, authenticated, unauthenticated }

class UserInfo {
  final String userId;
  final String userName;

  const UserInfo({required this.userId, required this.userName});
}

class AuthState {
  final AuthStatus status;
  final UserInfo? user;
  final String? error;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  AuthState copyWith({AuthStatus? status, UserInfo? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

// ============================================================
// AuthNotifier
// ============================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(const AuthState()) {
    _checkAuth();
  }

  void _checkAuth() {
    final token = _authRepo.token;
    if (token != null) {
      final user = _parseToken(token);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String userName, String password) async {
    try {
      await _authRepo.login(userName: userName, password: password);
      final token = _authRepo.token;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: token != null ? _parseToken(token) : null,
        error: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: '网络请求失败，请稍后重试');
    }
  }

  Future<void> register(String userName, String password) async {
    try {
      await _authRepo.register(userName: userName, password: password);
      state = state.copyWith(error: null);
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: '网络请求失败，请稍后重试');
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  ///解析用户信息
  UserInfo? _parseToken(String token) {
    final claims = JwtDecoder.decode(token);
    if (claims == null) return null;

    final userId = JwtDecoder.getUserId(claims);
    final userName = JwtDecoder.getUserName(claims);
    if (userId == null || userName == null) return null;

    return UserInfo(userId: userId, userName: userName);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
