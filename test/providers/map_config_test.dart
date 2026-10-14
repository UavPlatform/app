import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/models/amap_config.dart';
import 'package:uav_pilot_app/providers/map_provider.dart';
import '../pages/docs_alignment_test.dart' show overrides;
import '../test_support.dart';

void main() {
  test('Map configuration comes from the backend task/init endpoint', () async {
    final paths = <String>[];
    final adapter = StubAdapter((options) async {
      paths.add(options.uri.path);
      return jsonResponse(200, {
        'success': true,
        'data': {'key': 'backend-key', 'securityKey': 'backend-security'},
      });
    });
    final container = ProviderContainer(overrides: await overrides(adapter));
    addTearDown(container.dispose);
    final config = await container.read(amapMapConfigProvider.future);
    expect(paths, ['/task/init']);
    expect(config.key, 'backend-key');
    expect(config.securityKey, 'backend-security');
  });

  test('Empty backend Key reports missing credentials', () async {
    final adapter = StubAdapter(
      (_) async => jsonResponse(200, {
        'success': true,
        'data': {'key': '', 'securityKey': ''},
      }),
    );
    final container = ProviderContainer(overrides: await overrides(adapter));
    addTearDown(container.dispose);
    await expectLater(
      container.read(amapMapConfigProvider.future),
      throwsA(isA<MissingAndroidMapKeyException>()),
    );
  });

  test('Backend configuration can omit the unused JS securityKey', () async {
    expect(AmapConfig.fromJson({'key': 'android-key'}).securityKey, '');
    final adapter = StubAdapter(
      (_) async => jsonResponse(200, {
        'success': true,
        'data': {'key': 'backend-key'},
      }),
    );
    final container = ProviderContainer(overrides: await overrides(adapter));
    addTearDown(container.dispose);
    final config = await container.read(amapMapConfigProvider.future);
    expect(config.key, 'backend-key');
    expect(config.securityKey, '');
  });
}
