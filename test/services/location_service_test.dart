import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fuwaki.app/location');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('SDK coordinates and address are returned unchanged', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {
        'latitude': 27.91,
        'longitude': 112.91,
        'city': '湘潭市',
        'address': '作业点',
      },
    );
    final service = LocationService();
    addTearDown(service.dispose);
    final result = await service.getCurrentLocation();
    expect(result?.latitude, 27.91);
    expect(result?.longitude, 112.91);
    expect(result?.address, '作业点');
  });

  test('SDK failure does not return an invented location', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => {'errorCode': 12});
    final service = LocationService();
    addTearDown(service.dispose);
    expect(await service.getCurrentLocation(), isNull);
  });

  test('Disposal releases a pending SDK request', () async {
    final pending = Completer<Object?>();
    messenger.setMockMethodCallHandler(channel, (_) => pending.future);
    final service = LocationService();
    final request = service.getCurrentLocation();
    service.dispose();
    expect(await request, isNull);
    pending.complete(null);
  });
}
