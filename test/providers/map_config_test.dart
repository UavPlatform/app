import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/amap_config.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uav_pilot_app/api/http_client.dart';
import 'package:uav_pilot_app/providers/auth_provider.dart';
import 'package:uav_pilot_app/services/token_storage.dart';
import '../test_support.dart';

Future<List<Override>> overrides(StubAdapter adapter) async {
  SharedPreferences.setMockInitialValues({
    'jwt_token': makeJwt(userId: 7),
    'server_url': 'http://stub.local:8081',
  });
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    httpClientProvider.overrideWithValue(
      HttpClient(TokenStorage(prefs), adapter: adapter),
    ),
  ];
}

void main() {
  test('Map configuration comes from GET /config/map', () async {
    final paths = <String>[];
    final adapter = StubAdapter((options) async {
      paths.add(options.uri.path);
      return jsonResponse(200, {
        'success': true,
        'data': {'key': 'backend-key', 'serviceHost': null},
      });
    });
    final container = ProviderContainer(overrides: await overrides(adapter));
    addTearDown(container.dispose);
    final config = await container.read(amapMapConfigProvider.future);
    expect(paths, ['/config/map']);
    expect(config.key, 'backend-key');
  });

  test('Empty backend Key reports missing credentials', () async {
    final adapter = StubAdapter(
      (_) async => jsonResponse(200, {
        'success': true,
        'data': {'key': ''},
      }),
    );
    final container = ProviderContainer(overrides: await overrides(adapter));
    addTearDown(container.dispose);
    await expectLater(
      container.read(amapMapConfigProvider.future),
      throwsA(isA<MissingAndroidMapKeyException>()),
    );
  });

  test('Map config exposes key only, never securityKey or other secrets', () async {
    // 即使后端（误）下发 securityKey，原生端模型也不能携带它。
    final parsed = AmapConfig.fromJson({
      'key': 'android-key',
      'securityKey': 'leaked-secret',
      'serviceHost': null,
    });
    expect(parsed.key, 'android-key');
    // 契约模型本身就没有 securityKey 字段：序列化只剩 key（及可选 serviceHost）。
    final vo = ApiMapConfigVO.fromJson({'key': 'android-key', 'securityKey': 'leaked-secret'});
    final json = vo.toJson();
    expect(json.containsKey('securityKey'), isFalse);
    expect(json.keys.toSet().difference({'key', 'serviceHost'}), isEmpty);

    final adapter = StubAdapter(
      (_) async => jsonResponse(200, {
        'success': true,
        'data': {'key': 'backend-key', 'securityKey': 'leaked-secret'},
      }),
    );
    final container = ProviderContainer(overrides: await overrides(adapter));
    addTearDown(container.dispose);
    final config = await container.read(amapMapConfigProvider.future);
    expect(config.key, 'backend-key');
    expect(config.toString(), isNot(contains('leaked-secret')));
  });
}
