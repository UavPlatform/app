import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/token_storage.dart';
import 'generated/openapi_paths.dart';

class HttpClient {
  final TokenStorage _tokenStorage;

  /// 测试注入的自定义适配器（默认空，走真实网络栈）
  final HttpClientAdapter? adapter;
  late final Dio dio;

  Future<String?>? _refreshFuture;

  /// 无人机未绑定时回调
  static void Function()? onDroneRequired;

  /// 401 刷新失败的兜底回调（P1-4）：由认证层注册，
  /// 触发本地登出并经路由重定向回登录页。
  /// 仅对携带过 Authorization 头的请求触发（登录等匿名 401 不登出）。
  static void Function()? onUnauthorized;

  HttpClient(this._tokenStorage, {this.adapter}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.resolveHttpBaseUrl(_tokenStorage.getServerUrl()),
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final injected = adapter;
    if (injected != null) {
      dio.httpClientAdapter = injected;
    }

    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_droneCheckInterceptor());
    dio.interceptors.add(_refreshInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          logPrint: (message) => debugPrint(
            message.toString().replaceAllMapped(
              RegExp(r'("(?:key|securityKey|apiKey|uploadUrl|downloadUrl|userSig|privateMapKey)"\s*:\s*")[^"]*(")'),
              (match) => '${match[1]}<redacted>${match[2]}',
            ),
          ),
        ),
      );
    }
  }

  void updateBaseUrl(String url) {
    dio.options.baseUrl = ApiConfig.resolveHttpBaseUrl(
      TokenStorage.normalizeHttpServerUrl(url),
    );
  }

  InterceptorsWrapper _droneCheckInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final msg = error.response?.data?.toString() ?? '';
        if (msg.contains('请先绑定至少一台无人机')) {
          onDroneRequired?.call();
        }
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _tokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  static const _retryKey = '_tokenRetried';

  InterceptorsWrapper _refreshInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        final hadAuthHeader =
            error.requestOptions.headers['Authorization'] != null;

        if (error.requestOptions.extra[_retryKey] == true) {
          // 已用新 token 重试仍 401：会话彻底失效。
          _notifyUnauthorized(hadAuthHeader);
          return handler.next(error);
        }

        _refreshFuture ??= _refreshAccessToken();
        try {
          final newToken = await _refreshFuture;
          if (newToken == null) {
            _notifyUnauthorized(hadAuthHeader);
            return handler.next(error);
          }

          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          opts.extra[_retryKey] = true;
          try {
            final retryResponse = await dio.fetch(opts);
            handler.resolve(retryResponse);
          } catch (e) {
            // 重试失败：401 场景已在重试请求的拦截器中触发登出通知，
            // 这里不重复通知，仅透传原始错误。
            handler.next(error);
          }
        } finally {
          _refreshFuture = null;
        }
      },
    );
  }

  void _notifyUnauthorized(bool hadAuthHeader) {
    if (hadAuthHeader) onUnauthorized?.call();
  }

  /// 主动刷新 accessToken（t28：WS 握手 403 自愈入口）。
  /// 返回三态：refreshed（已持久化新 token）/ rejected（服务端明确拒绝，
  /// 会话彻底失效）/ unreachable（网络性失败，可稍后重试）。
  Future<TokenRefreshOutcome> refreshTokens() async {
    final refreshToken = _tokenStorage.getRefreshToken();
    if (refreshToken == null) return TokenRefreshOutcome.rejected;

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.resolveHttpBaseUrl(_tokenStorage.getServerUrl()),
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ),
    );
    final injected = adapter;
    if (injected != null) {
      refreshDio.httpClientAdapter = injected;
    }

    try {
      final response = await refreshDio.post(
        ApiPaths.userRefresh,
        options: Options(headers: {'Refresh-Token': refreshToken}),
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final newToken = data['data']['token'] as String;
        await _tokenStorage.saveTokens(
          token: newToken,
          refreshToken: refreshToken,
        );
        return TokenRefreshOutcome.refreshed;
      }
      return TokenRefreshOutcome.rejected;
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status >= 500) return TokenRefreshOutcome.unreachable;
      if (e.response != null) return TokenRefreshOutcome.rejected;
      return TokenRefreshOutcome.unreachable;
    } catch (_) {
      return TokenRefreshOutcome.unreachable;
    }
  }

  Future<String?> _refreshAccessToken() async {
    final outcome = await refreshTokens();
    return outcome == TokenRefreshOutcome.refreshed
        ? _tokenStorage.getToken()
        : null;
  }
}
