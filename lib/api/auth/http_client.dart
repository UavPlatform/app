import 'dart:async';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../services/token_storage.dart';

class HttpClient {
  final TokenStorage _tokenStorage;
  late final Dio dio;

  Future<String?>? _refreshFuture;

  HttpClient(this._tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_refreshInterceptor());
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
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

  InterceptorsWrapper _refreshInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        _refreshFuture ??= _refreshAccessToken();
        final newToken = await _refreshFuture;
        _refreshFuture = null;

        if (newToken == null) {
          return handler.next(error);
        }

        final opts = error.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await dio.fetch(opts);
          handler.resolve(retryResponse);
        } catch (e) {
          handler.next(error);
        }
      },
    );
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
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
