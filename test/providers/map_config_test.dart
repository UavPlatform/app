import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
