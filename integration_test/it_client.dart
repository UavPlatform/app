import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/auth_api.dart';
import 'package:uav_pilot_app/api/dispatch_order_api.dart';
import 'package:uav_pilot_app/api/equipment_api.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/api/rider_account_api.dart';
import 'package:uav_pilot_app/models/login_request.dart';
import 'package:uav_pilot_app/models/register_request.dart';
import 'package:uav_pilot_app/services/token_storage.dart';

import 'it_config.dart';

/// 对接真实后端的轻量客户端（复用生产 API 层，不走 mock）。
class ItClient {
  ItClient._(this.prefs, this.storage, this.http)
    : auth = AuthApi(http),
      rider = RiderAccountApi(http),
      equipment = EquipmentApi(http),
      orders = DispatchOrderApi(http);

  final SharedPreferences prefs;
  final TokenStorage storage;
  final HttpClient http;
  final AuthApi auth;
  final RiderAccountApi rider;
  final EquipmentApi equipment;
  final DispatchOrderApi orders;

  static Future<ItClient> create() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = TokenStorage(prefs);
    await storage.saveServerUrl(ItConfig.baseUrl);
    final http = HttpClient(storage);
    http.updateBaseUrl(ItConfig.baseUrl);
    // 与后端 TestAccounts 同口径：每次请求换唯一客户端 IP，避开登录/注册限流。
    http.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final n = Random().nextInt(200) + 1;
          options.headers['X-Forwarded-For'] = '127.0.0.$n';
          handler.next(options);
        },
      ),
    );
    return ItClient._(prefs, storage, http);
  }

  Future<void> loginUser(String userName, String password) async {
    final result = await auth.login(
      LoginRequest(userName: userName, password: password),
    );
    if (!result.success || result.data == null) {
      throw StateError('登录失败: $userName ${result.message}');
    }
    await storage.saveTokens(
      token: result.data!.token,
      refreshToken: result.data!.refreshToken,
    );
  }

  Future<void> registerCustomer(String userName, String password) async {
    final result = await auth.register(
      RegisterRequest(userName: userName, password: password),
    );
    if (!result.success) {
      throw StateError('注册失败: $userName ${result.message}');
    }
  }

  Future<void> registerPilot(String userName, String password) async {
    final result = await rider.register(
      userName: userName,
      password: password,
    );
    if (!result.success || result.data == null) {
      throw StateError('飞手注册失败: $userName ${result.message}');
    }
    await storage.saveTokens(
      token: result.data!.token,
      refreshToken: result.data!.refreshToken,
    );
  }

  Future<void> clearSession() => storage.clear();
}
