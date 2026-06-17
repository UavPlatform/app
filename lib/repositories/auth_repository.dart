import '../api/auth/auth_api.dart';
import '../services/token_storage.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';

class AuthRepository {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  AuthRepository(this._authApi, this._tokenStorage);

  Future<void> login({
    required String userName,
    required String password,
  }) async {
    final result = await _authApi.login(
      LoginRequest(userName: userName, password: password),
    );

    if (!result.success || result.data == null) {
      throw AuthException(
        result.code ?? 400,
        result.message ?? '登录失败',
      );
    }

    final loginData = result.data!;
    await _tokenStorage.saveTokens(
      token: loginData.token,
      refreshToken: loginData.refreshToken,
    );
  }

  Future<void> register({
    required String userName,
    required String password,
  }) async {
    final result = await _authApi.register(
      RegisterRequest(userName: userName, password: password),
    );

    if (!result.success) {
      throw AuthException(
        result.code ?? 400,
        result.message ?? '注册失败',
      );
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  bool get isLoggedIn => _tokenStorage.hasToken;

  String? get token => _tokenStorage.getToken();
}

class AuthException implements Exception {
  final int code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => 'AuthException($code): $message';
}
