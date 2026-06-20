import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../services/token_storage.dart';
import '../services/jwt_decoder.dart';
import '../api/http_client.dart';
import '../api/auth_api.dart';

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

// ============================================================
// 认证状态
// ============================================================

enum AuthStatus { unknown, authenticated, unauthenticated }

class UserInfo {
  final String userId;
  final String userName;
  final int role;

  const UserInfo({required this.userId, required this.userName, this.role = 0});

  bool get isPilot => role == 1;
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
  final AuthApi _api;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._api, this._tokenStorage) : super(const AuthState()) {
    _checkAuth();
  }

  void _checkAuth() {
    final token = _tokenStorage.getToken();
    if (token != null) {
      final user = _parseToken(token);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String userName, String password) async {
    try {
      final result = await _api.login(LoginRequest(userName: userName, password: password));
      if (!result.success || result.data == null) {
        state = state.copyWith(error: result.message ?? '登录失败');
        return;
      }
      await _tokenStorage.saveTokens(
        token: result.data!.token,
        refreshToken: result.data!.refreshToken,
      );
      final token = _tokenStorage.getToken();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: token != null ? _parseToken(token) : null,
        error: null,
      );
    } catch (_) {
      state = state.copyWith(error: '网络请求失败，请稍后重试');
    }
  }

  Future<void> register(String userName, String password) async {
    try {
      final result = await _api.register(RegisterRequest(userName: userName, password: password));
      if (!result.success) {
        state = state.copyWith(error: result.message ?? '注册失败');
        return;
      }
      state = state.copyWith(error: null);
    } catch (_) {
      state = state.copyWith(error: '网络请求失败，请稍后重试');
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  UserInfo? _parseToken(String token) {
    final claims = JwtDecoder.decode(token);
    if (claims == null) return null;

    final userId = JwtDecoder.getUserId(claims);
    final userName = JwtDecoder.getUserName(claims);
    if (userId == null || userName == null) return null;

    final role = JwtDecoder.getRole(claims);
    return UserInfo(userId: userId, userName: userName, role: role);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authApiProvider), ref.watch(tokenStorageProvider)),
);
