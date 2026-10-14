// HttpClient 通信健壮性测试（P1-4 401 刷新失败登出、P1-5 baseUrl 缺省策略）。

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/config/api_config.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import '../test_support.dart';

void main() {
  tearDown(() {
    HttpClient.onUnauthorized = null;
    HttpClient.onDroneRequired = null;
  });

  Future<HttpClient> clientWith(
    Map<String, Object> prefsValues,
    StubAdapter adapter,
  ) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return HttpClient(TokenStorage(prefs), adapter: adapter);
  }

  group('baseUrl 缺省策略（P1-5）', () {
    test('新装首启无 serverUrl 时使用内置默认地址', () async {
      final client = await clientWith(const {}, StubAdapter((_) async {
        return jsonResponse(200, {'success': false});
      }));
      expect(client.dio.options.baseUrl, '${ApiConfig.defaultBaseUrl}/');
    });

    test('已持久化地址优先于内置默认地址', () async {
      final client = await clientWith(
        const {'server_url': 'http://192.168.1.5:9000'},
        StubAdapter((_) async => jsonResponse(200, {'success': false})),
      );
      expect(client.dio.options.baseUrl, 'http://192.168.1.5:9000/api/');
    });

    test('空白 serverUrl 视为未配置，回落默认地址', () async {
      final client = await clientWith(
        const {'server_url': '   '},
        StubAdapter((_) async => jsonResponse(200, {'success': false})),
      );
      expect(client.dio.options.baseUrl, '${ApiConfig.defaultBaseUrl}/');
    });

    test('仅 host:port 时自动补 http:// 且经网关时 REST 走 /api/', () async {
      final client = await clientWith(
        const {'server_url': '120.77.170.101:8888'},
        StubAdapter((_) async => jsonResponse(200, {'success': false})),
      );
      expect(client.dio.options.baseUrl, 'http://120.77.170.101:8888/api/');
    });

    test('直连 Spring :8081 时不加 /api 前缀', () async {
      final client = await clientWith(
        const {'server_url': 'http://192.168.1.5:8081'},
        StubAdapter((_) async => jsonResponse(200, {'success': false})),
      );
      expect(client.dio.options.baseUrl, 'http://192.168.1.5:8081/');
    });
  });

  group('401 刷新失败登出（P1-4）', () {
    test('刷新失败触发 onUnauthorized，错误透传给调用方', () async {
      final adapter = StubAdapter((options) async {
        if (options.uri.path.contains('/user/refresh')) {
          return jsonResponse(401, {'success': false, 'message': 'expired'});
        }
        return jsonResponse(401, {'success': false, 'message': 'token expired'});
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'jwt_refresh_token': 'r-1',
        'server_url': 'http://stub.local:8081',
      }, adapter);
      final unauthorizedCalls = <int>[];
      HttpClient.onUnauthorized = () => unauthorizedCalls.add(1);

      await expectLater(
        client.dio.get('/chat/session/list'),
        throwsA(isA<DioException>()),
      );
      expect(unauthorizedCalls, hasLength(1));

      // 刷新请求按契约携带 Refresh-Token 头
      final refreshCall = adapter.requests.firstWhere(
        (r) => r.uri.path.contains('/user/refresh'),
      );
      expect(refreshCall.headers['Refresh-Token'], 'r-1');
    });

    test('刷新成功后用新 token 重试且不触发登出', () async {
      final adapter = StubAdapter((options) async {
        if (options.uri.path.contains('/user/refresh')) {
          return jsonResponse(200, {
            'success': true,
            'data': {'token': 'new-token', 'refreshToken': 'r-1'},
          });
        }
        if (options.extra['_tokenRetried'] == true) {
          return jsonResponse(200, {'success': true, 'code': 200, 'data': []});
        }
        return jsonResponse(401, {'success': false, 'message': 'token expired'});
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'jwt_refresh_token': 'r-1',
        'server_url': 'http://stub.local:8081',
      }, adapter);
      final unauthorizedCalls = <int>[];
      HttpClient.onUnauthorized = () => unauthorizedCalls.add(1);

      final response = await client.dio.get('/chat/session/list');
      expect(response.statusCode, 200);
      expect(unauthorizedCalls, isEmpty);

      final secureCalls = adapter.requests
          .where((r) => !r.uri.path.contains('/user/refresh'))
          .toList();
      expect(secureCalls, hasLength(2), reason: '原请求 + 新 token 重试');
      expect(secureCalls.last.headers['Authorization'], 'Bearer new-token');
    });

    test('匿名请求 401（如登录密码错误）不触发登出', () async {
      final adapter = StubAdapter((options) async {
        return jsonResponse(401, {'success': false, 'message': 'bad credentials'});
      });
      // 未登录状态：无任何 token
      final client = await clientWith(const {'server_url': 'http://stub.local:8081'}, adapter);
      final unauthorizedCalls = <int>[];
      HttpClient.onUnauthorized = () => unauthorizedCalls.add(1);

      await expectLater(
        client.dio.post('/user/login', data: {'userName': 'u', 'password': 'p'}),
        throwsA(isA<DioException>()),
      );
      expect(unauthorizedCalls, isEmpty, reason: '未携带 Authorization 的 401 不应登出');
      expect(
        adapter.requests.where((r) => r.uri.path.contains('/user/refresh')),
        isEmpty,
        reason: '无 refreshToken 时不应尝试刷新',
      );
    });

    test('刷新成功但重试仍 401 时触发登出', () async {
      final adapter = StubAdapter((options) async {
        if (options.uri.path.contains('/user/refresh')) {
          return jsonResponse(200, {
            'success': true,
            'data': {'token': 'new-token', 'refreshToken': 'r-1'},
          });
        }
        return jsonResponse(401, {'success': false, 'message': 'token expired'});
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'jwt_refresh_token': 'r-1',
        'server_url': 'http://stub.local:8081',
      }, adapter);
      final unauthorizedCalls = <int>[];
      HttpClient.onUnauthorized = () => unauthorizedCalls.add(1);

      await expectLater(
        client.dio.get('/chat/session/list'),
        throwsA(isA<DioException>()),
      );
      expect(unauthorizedCalls, hasLength(1), reason: '重试用新 token 仍 401 → 会话失效');
    });

    test('非 401 错误不触发登出', () async {
      final adapter = StubAdapter((options) async {
        return jsonResponse(500, {'success': false, 'message': 'boom'});
      });
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'jwt_refresh_token': 'r-1',
        'server_url': 'http://stub.local:8081',
      }, adapter);
      final unauthorizedCalls = <int>[];
      HttpClient.onUnauthorized = () => unauthorizedCalls.add(1);

      await expectLater(
        client.dio.get('/chat/session/list'),
        throwsA(isA<DioException>()),
      );
      expect(unauthorizedCalls, isEmpty);
    });
  });

  group('refreshTokens() 三态（t28②：WS 403 自愈入口）', () {
    test('刷新成功 → refreshed 且新 token 已持久化', () async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': makeJwt(userId: 7),
        'jwt_refresh_token': 'r-1',
        'server_url': 'http://stub.local:8081',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = TokenStorage(prefs);
      final client = HttpClient(storage, adapter: StubAdapter((options) async {
        return jsonResponse(200, {
          'success': true,
          'data': {'token': 'fresh-token', 'refreshToken': 'r-1'},
        });
      }));

      final outcome = await client.refreshTokens();

      expect(outcome, TokenRefreshOutcome.refreshed);
      expect(storage.getToken(), 'fresh-token', reason: '新 token 应已持久化');
    });

    test('refreshToken 缺失 → rejected', () async {
      final client = await clientWith(
        const {'server_url': 'http://stub.local:8081'},
        StubAdapter((_) async => jsonResponse(200, {'success': true})),
      );
      expect(
        await client.refreshTokens(),
        TokenRefreshOutcome.rejected,
      );
    });

    test('服务端 4xx 拒绝 → rejected；5xx → unreachable', () async {
      var status = 401;
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'jwt_refresh_token': 'r-1',
        'server_url': 'http://stub.local:8081',
      }, StubAdapter((options) async {
        return jsonResponse(status, {'success': false});
      }));

      expect(await client.refreshTokens(), TokenRefreshOutcome.rejected);

      status = 500;
      expect(
        await client.refreshTokens(),
        TokenRefreshOutcome.unreachable,
        reason: '5xx 为服务端瞬时故障，不应视为会话失效',
      );
    });

    test('连接层失败（无法触达服务端）→ unreachable', () async {
      final client = await clientWith({
        'jwt_token': makeJwt(userId: 7),
        'jwt_refresh_token': 'r-1',
        'server_url': 'http://stub.local:8081',
      }, StubAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'network unreachable',
        );
      }));

      expect(
        await client.refreshTokens(),
        TokenRefreshOutcome.unreachable,
      );
    });
  });
}
