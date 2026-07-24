import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/token_storage.dart';

class HttpClient {
  final TokenStorage _tokenStorage;
  late final Dio dio;

  Future<String?>? _refreshFuture;

  HttpClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_refreshInterceptor());
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
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

        if (error.requestOptions.extra[_retryKey] == true) {
          return handler.next(error);
        }

        _refreshFuture ??= _refreshAccessToken();
        try {
          final newToken = await _refreshFuture;
          if (newToken == null) {
            return handler.next(error);
          }

          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          opts.extra[_retryKey] = true;
          try {
            final retryResponse = await dio.fetch(opts);
            handler.resolve(retryResponse);
          } catch (e) {
            handler.next(error);
          }
        } finally {
          _refreshFuture = null;
        }
      },
    );
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response =
          await Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            ),
          ).post(
            '/user/refresh',
            options: Options(headers: {'Refresh-Token': refreshToken}),
          );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final newToken = data['data']['token'] as String;
        await _tokenStorage.saveTokens(
          token: newToken,
          refreshToken: refreshToken,
        );
        return newToken;
      }
      // refresh 返回了非成功响应（如 token 也过期了）
      return null;
    } catch (e) {
      // refresh 请求本身失败（网络不通 / 接口不存在等）
      return null;
    }
  }
}
