import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/services/phone_dialer.dart';

void main() {
  test(
    'validated contact opens a tel URI rather than calling directly',
    () async {
      Uri? opened;
      final dialer = PhoneDialer(
        launch: (uri) async {
          opened = uri;
          return true;
        },
      );
      expect(await dialer.dial('+86 (138) 0000-0000'), isTrue);
      expect(opened!.scheme, 'tel');
      expect(opened!.path, '+8613800000000');
    },
  );
  test(
    'invalid phone and unavailable platform return a manual-dial fallback',
    () async {
      var calls = 0;
      final dialer = PhoneDialer(
        launch: (_) async {
          calls++;
          throw StateError('not supported');
        },
      );
      expect(await dialer.dial('https://example.com'), isFalse);
      expect(calls, 0);
      expect(await dialer.dial('13800000000'), isFalse);
      expect(calls, 1);
    },
  );
}
