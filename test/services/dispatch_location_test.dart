import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/services/dispatch_location.dart';

Map<String, dynamic> validFix([int? now]) => {
  'latitude': 28.2,
  'longitude': 113.0,
  'accuracyMeters': 12.0,
  'capturedAt': now ?? DateTime.now().millisecondsSinceEpoch,
  'coordinateSystem': 'GCJ02',
  'mocked': false,
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'requires complete fresh real GCJ fix without substituting zero coordinates',
    () {
      final now = DateTime.now();
      expect(
        DispatchLocationFix.fromMap(
          validFix(now.millisecondsSinceEpoch),
        ).validAt(now),
        isTrue,
      );
      for (final patch in [
        {'mocked': true},
        {'coordinateSystem': 'WGS84'},
        {'latitude': double.nan},
        {'longitude': 181},
        {'accuracyMeters': -1},
        {'capturedAt': now.millisecondsSinceEpoch - 300001},
        {'capturedAt': now.millisecondsSinceEpoch + 30001},
      ]) {
        expect(
          DispatchLocationFix.fromMap({
            ...validFix(now.millisecondsSinceEpoch),
            ...patch,
          }).validAt(now),
          isFalse,
        );
      }
      expect(DispatchLocationFix.fromMap({}).validAt(now), isFalse);
    },
  );
  test(
    'requests the dedicated fresh-fix channel and does not fall back after permission errors',
    () async {
      final calls = <String>[];
      var denied = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DispatchLocation.channel, (call) async {
            calls.add(call.method);
            if (call.method == 'setApiKey') return true;
            if (denied) {
              throw PlatformException(code: 'LOCATION_PERMISSION_DENIED');
            }
            return validFix();
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(DispatchLocation.channel, null),
      );
      expect(
        (await DispatchLocation().locate('test-config')).coordinateSystem,
        'GCJ02',
      );
      denied = true;
      await expectLater(
        DispatchLocation().locate('test-config'),
        throwsA(isA<PlatformException>()),
      );
      expect(calls.where((method) => method == 'getLocation'), isEmpty);
    },
  );
}
