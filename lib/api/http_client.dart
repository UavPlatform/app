import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/token_storage.dart';

class HttpClient {
  final TokenStorage _tokenStorage;
  late final Dio dio;

  Future<String?>? _refreshFuture;

  /// 无人机未绑定时回调
  static void Function()? onDroneRequired;

  HttpClient(this._tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: _tokenStorage.getServerUrl() ?? '',
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_droneCheckInterceptor());
    dio.interceptors.add(_refreshInterceptor());
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
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
      final response = await Dio(BaseOptions(
        baseUrl: _tokenStorage.getServerUrl() ?? '',
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      )).post(
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
    } catch (_) {}
    return null;
  }
}
